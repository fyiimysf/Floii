import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';

/// Fires [onConfirmed] only after the user presses and holds for [duration].
///
/// Releasing early or dragging away cancels, so the gesture itself is the
/// confirmation and no dialog is needed. Progress fills as a bar along the
/// bottom edge, clipped to [borderRadius] so it follows the card's corners, and
/// the surface takes a faint tint of [color] so the hold reads at a glance.
///
/// While the hold is in progress the device buzzes more insistently the longer
/// it is held: pulses start sparse and step up in both rate and strength, and
/// stop the instant the hold completes or the finger lifts. That gives a
/// destructive action a physical "you are close, let go to stop" signal without
/// needing any text.
///
/// Built on [Listener] rather than [GestureDetector]: tap callbacks only fire
/// once the gesture arena resolves, which stalls the timer by a frame or two,
/// and raw pointer events also let a drag off the tile cancel the hold.
class HoldToConfirm extends StatefulWidget {
  const HoldToConfirm({
    super.key,
    required this.child,
    required this.onConfirmed,
    this.duration = const Duration(milliseconds: 500),
    this.color = AppColors.error,
    this.haptics = true,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(AppDimensions.radiusLarge),
    ),
  });

  final Widget child;

  /// Runs once the hold completes. Guarded so a held finger cannot fire twice.
  final VoidCallback onConfirmed;

  final Duration duration;
  final Color color;

  /// Whether to buzz at all, including on completion. See the class docs for
  /// the ramp.
  final bool haptics;

  final BorderRadius borderRadius;

  @override
  State<HoldToConfirm> createState() => _HoldToConfirmState();
}

class _HoldToConfirmState extends State<HoldToConfirm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  /// Set once the hold completes so releasing the finger afterwards, or
  /// starting another hold, cannot trigger the action twice.
  bool _fired = false;

  /// Used to detect a drag off the tile.
  final GlobalKey _key = GlobalKey();

  /// Drives the haptic ramp. One-shot rather than periodic, because the gap
  /// shrinks as the hold fills.
  Timer? _pulse;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_handleStatus);
  }

  @override
  void dispose() {
    _stopBuzzing();
    _controller.removeStatusListener(_handleStatus);
    _controller.dispose();
    super.dispose();
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_fired) {
      _fired = true;
      _stopBuzzing();
      if (widget.haptics) HapticFeedback.heavyImpact();
      widget.onConfirmed();
    }
  }

  /// Gap between buzzes, shrinking from [_slowestGap] to [_fastestGap] as the
  /// hold fills.
  static const Duration _slowestGap = Duration(milliseconds: 300);
  static const Duration _fastestGap = Duration(milliseconds: 90);

  /// Buzz strength steps up across the hold so the escalation is felt, not just
  /// heard as a faster tick.
  void _buzz(double progress) {
    if (progress < 0.34) {
      HapticFeedback.selectionClick();
    } else if (progress < 0.68) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  Duration _gapFor(double progress) => Duration(
        milliseconds: (_slowestGap.inMilliseconds -
                (_slowestGap.inMilliseconds - _fastestGap.inMilliseconds) *
                    progress)
            .round(),
      );

  void _startBuzzing() {
    _stopBuzzing();
    if (!widget.haptics) return;
    _buzz(_controller.value);
    _schedulePulse();
  }

  void _schedulePulse() {
    final progress = _controller.value;
    if (_fired || progress >= 1) return;
    _pulse = Timer(_gapFor(progress), () {
      if (_fired) return;
      _buzz(_controller.value);
      _schedulePulse();
    });
  }

  void _stopBuzzing() {
    _pulse?.cancel();
    _pulse = null;
  }

  void _start() {
    if (_fired) return;
    _controller.forward(from: 0);
    _startBuzzing();
  }

  void _cancel() {
    // Snap back rather than winding down: the user let go, so the affordance
    // and the buzzing should stop immediately instead of lingering.
    _stopBuzzing();
    _controller.value = 0;

    // Releasing the latch here is what lets the tile recover after a completed
    // hold. `_handleStatus` sets it so a finger that is still down cannot fire
    // the action a second time; by the time the finger lifts the hold is over,
    // and leaving it latched would strand the bar at 100% and kill the tile.
    _fired = false;
  }

  /// Cancels once the finger leaves the tile, so the hold has to stay in place.
  void _handleMove(PointerMoveEvent event) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    if (!(Offset.zero & box.size).contains(box.globalToLocal(event.position))) {
      _cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      // A pure gesture is unreachable by screen readers and keyboards, so
      // expose the same action as a long press.
      onLongPress: widget.onConfirmed,
      child: Listener(
        // Opaque, not deferToChild: a tap in the gap between two words, or on
        // the padding around the label, must still start the hold.
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _start(),
        onPointerUp: (_) => _cancel(),
        onPointerCancel: (_) => _cancel(),
        onPointerMove: _handleMove,
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: AnimatedBuilder(
            animation: _controller,
            child: KeyedSubtree(key: _key, child: widget.child),
            builder: (context, child) {
              final t = Curves.easeOut.transform(_controller.value);

              return Stack(
                children: [
                  child!,
                  if (t > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ColoredBox(
                          color: widget.color.withValues(alpha: 0.10 * t),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: FractionallySizedBox(
                      widthFactor: t,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: widget.color,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
