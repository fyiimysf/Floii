import 'dart:async';

import 'package:flutter/material.dart';

import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';

/// State of the toast currently on screen, so a second toast can retire the
/// first instead of stacking on top of it. A plain reference rather than a
/// [GlobalKey]: the outgoing toast is still mounted while it animates away, and
/// reusing a key for its replacement would trip the duplicate-key assertion.
_TopToastState? _activeToast;

OverlayEntry? _activeEntry;

/// Shows a transient message pinned below the status bar.
///
/// [SnackBar] is always bottom-anchored in Flutter, which puts it right where
/// the navigation bar and the primary action live. This drops an entry into the
/// root overlay instead, so confirmations arrive where they cannot cover either.
///
/// Only one toast is shown at a time; calling this again retires the previous
/// one. It animates itself away after [duration] and does not need to be closed
/// by the caller.
Future<void> showTopToast(
  BuildContext context, {
  required String message,
  IconData icon = Icons.check_circle_outline,
  Color color = AppColors.success,
  Duration duration = const Duration(seconds: 2),
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  _dismissTopToast();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _TopToast(
      message: message,
      icon: icon,
      color: color,
      duration: duration,
      onDismissed: () {
        if (identical(_activeEntry, entry)) _activeEntry = null;
        if (entry.mounted) entry.remove();
      },
    ),
  );
  _activeEntry = entry;
  overlay.insert(entry);
}

/// Retires the visible toast early. Safe to call when nothing is showing.
void _dismissTopToast() => _activeToast?.dismiss();

class _TopToast extends StatefulWidget {
  const _TopToast({
    required this.message,
    required this.icon,
    required this.color,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final IconData icon;
  final Color color;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 180),
  );

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _activeToast = this;
    _controller.forward();
    _timer = Timer(widget.duration, dismiss);
  }

  Future<void> dismiss() async {
    _timer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    if (!mounted) return;
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (identical(_activeToast, this)) _activeToast = null;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      // Let taps fall through: the toast is a confirmation, not a control.
      child: IgnorePointer(
        child: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _curve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -1),
                end: Offset.zero,
              ).animate(_curve),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.elementSpacing,
                    vertical: AppDimensions.elementSpacing,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.95),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Icon(widget.icon, color: Colors.white),
                      const SizedBox(width: AppDimensions.elementSpacing),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
