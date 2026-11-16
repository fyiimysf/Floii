import 'dart:async';

import 'package:flutter/material.dart';

/// Fades and lifts [child] into place the first time it is built.
///
/// Deliberately fires on mount only: the surrounding screens rebuild whenever
/// Hive changes, and re-running the animation on every rebuild would make the
/// whole page twitch each time a value is edited.
///
/// Honours the OS "reduce motion" setting, in which case [child] is shown
/// straight away with no movement.
class EntranceFadeRise extends StatefulWidget {
  const EntranceFadeRise({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.rise = 14,
    this.duration = const Duration(milliseconds: 340),
  });

  final Widget child;

  /// Staggers siblings: each card passes a slightly longer delay than the last
  /// so a list arrives in sequence rather than all at once.
  final Duration delay;

  /// How far below its final position the child starts, in logical pixels.
  final double rise;

  final Duration duration;

  @override
  State<EntranceFadeRise> createState() => _EntranceFadeRiseState();
}

class _EntranceFadeRiseState extends State<EntranceFadeRise>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  Timer? _delayTimer;

  bool _started = false;

  // Started from here rather than initState because reading the reduced-motion
  // flag means reading MediaQuery, and inherited widgets are not safe to touch
  // until dependencies have been established.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      // Reduced motion: land immediately, leaving no ticker running.
      _controller.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, _controller.forward);
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    return AnimatedBuilder(
      animation: curved,
      // Only the transform and opacity change, so there is nothing for the
      // child to repaint while this runs.
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, widget.rise * (1 - curved.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Builds [children] with each one entering slightly after the last, for lists
/// of cards that should cascade in.
///
/// Children keep their identity, so rebuilding the list does not replay the
/// animation.
class StaggeredColumn extends StatelessWidget {
  const StaggeredColumn({
    super.key,
    required this.children,
    this.stagger = const Duration(milliseconds: 60),
    this.axis = Axis.vertical,
    this.spacing = 0,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final Duration stagger;
  final Axis axis;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    // No reduced-motion branch here: EntranceFadeRise ignores its delay when
    // motion is off, so zeroing the stagger would change nothing.
    return Flex(
      direction: axis,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0 && spacing > 0)
            SizedBox(
              height: axis == Axis.vertical ? spacing : null,
              width: axis == Axis.horizontal ? spacing : null,
            ),
          EntranceFadeRise(delay: stagger * i, child: children[i]),
        ],
      ],
    );
  }
}

/// Like [EntranceFadeRise], but replays every time [isActive] turns true rather
/// than only on first build.
///
/// Used for tabs, which stay alive in an `IndexedStack`: selecting one should
/// feel like arriving somewhere, not like a frame swap.
class EntranceOnActivate extends StatefulWidget {
  const EntranceOnActivate({
    super.key,
    required this.isActive,
    required this.child,
    this.rise = 10,
    this.duration = const Duration(milliseconds: 280),
  });

  final bool isActive;
  final Widget child;
  final double rise;
  final Duration duration;

  @override
  State<EntranceOnActivate> createState() => _EntranceOnActivateState();
}

class _EntranceOnActivateState extends State<EntranceOnActivate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  bool _started = false;

  // Not initState: _play reads MediaQuery, which is not available that early.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.isActive) _play();
  }

  @override
  void didUpdateWidget(covariant EntranceOnActivate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _play();
  }

  void _play() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    return AnimatedBuilder(
      animation: curved,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, widget.rise * (1 - curved.value)),
          child: child,
        ),
      ),
    );
  }
}
