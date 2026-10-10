import 'package:flutter/widgets.dart';

/// Screen width (logical px) the layouts were designed against — the same
/// reference the global text scaling in `app_text_scaling.dart` uses.
const double kReferenceWidth = 390;

/// Below this width a phone is narrow enough that side-by-side rows run out of
/// room and start clipping labels.
const double kCompactWidth = 380;

/// At or above this width there is room for genuinely wide, inline rows
/// (tablets, unfolded devices).
const double kExpandedWidth = 600;

/// Width buckets used to drive layout decisions.
///
/// Rather than hard-coding pixel maths per widget, widgets ask for the bucket
/// and adapt: stacked/2-up on [compact], inline rows on [regular] and
/// [expanded].
enum ScreenSize {
  compact,
  regular,
  expanded;

  /// Buckets a window size by its shortest logical side, so landscape and
  /// split-screen pick a sensible bucket instead of the raw window width.
  static ScreenSize fromSize(Size size) => fromWidth(size.shortestSide);

  static ScreenSize fromWidth(double width) {
    if (width < kCompactWidth) return ScreenSize.compact;
    if (width < kExpandedWidth) return ScreenSize.regular;
    return ScreenSize.expanded;
  }

  bool get isCompact => this == ScreenSize.compact;

  bool get isExpanded => this == ScreenSize.expanded;

  /// Column count for a metric grid: two-up on narrow phones, three across
  /// once there is room for them to read as inline rows.
  int get gridColumns => isCompact ? 2 : 3;

  /// Spacing multiplier — tightens up on narrow screens so fixed-height
  /// widgets keep enough room for their text.
  double get spacingFactor => isCompact ? 0.75 : (isExpanded ? 1.1 : 1.0);
}

/// Screen-relative sizing helpers for `BuildContext`.
extension ResponsiveContext on BuildContext {
  /// Shortest logical side of the current window.
  double get screenWidth => MediaQuery.sizeOf(this).shortestSide;

  ScreenSize get screenSize => ScreenSize.fromSize(MediaQuery.sizeOf(this));

  bool get isCompactScreen => screenSize.isCompact;

  /// Scales a length proportionally to the screen width, relative to
  /// [kReferenceWidth], clamped so a very narrow phone does not shrink a
  /// component into illegibility and a tablet does not blow it up.
  double scaleLength(double value, {double min = 0.78, double max = 1.2}) =>
      value * (screenWidth / kReferenceWidth).clamp(min, max);
}
