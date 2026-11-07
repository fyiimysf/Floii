import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';

/// The hero on the first onboarding page: a cycle drawn as a ring of
/// phase-coloured arcs.
///
/// The arcs draw themselves on once when the page appears, and a faint halo of
/// ticks turns slowly around them so the mark feels alive without pulling
/// attention from the copy. Both effects are dropped under reduced motion.
class CycleRingIllustration extends StatefulWidget {
  const CycleRingIllustration({super.key, this.size = 232});

  final double size;

  @override
  State<CycleRingIllustration> createState() => _CycleRingIllustrationState();
}

class _CycleRingIllustrationState extends State<CycleRingIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _draw.value = 1;
      return;
    }
    _draw.forward();
    _spin.repeat();
  }

  @override
  void dispose() {
    _draw.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_draw, _spin]),
        builder: (context, _) => CustomPaint(
          painter: _CycleRingPainter(
            draw: Curves.easeOutCubic.transform(_draw.value),
            spin: _spin.value,
            isDark: isDark,
          ),
          child: Center(child: _CenterMark(isDark: isDark)),
        ),
      ),
    );
  }
}

/// Tile in the middle of the ring, carrying the app mark on a soft glow.
class _CenterMark extends StatelessWidget {
  const _CenterMark({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        // color: isDark ? AppColors.cardDark : Colors.white,
        boxShadow: [
          // BoxShadow(
          //   color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.26),
          //   blurRadius: 34,
          //   offset: const Offset(0, 14),
          // ),
        ],
      ),
      child: Image.asset('lib/icons/foreground.png', fit: BoxFit.cover),
    );
  }
}

class _CycleRingPainter extends CustomPainter {
  _CycleRingPainter({
    required this.draw,
    required this.spin,
    required this.isDark,
  });

  final double draw;
  final double spin;
  final bool isDark;

  /// Rough share of a 28-day cycle spent in each phase, so the ring reads as a
  /// real cycle rather than four equal slices.
  static const List<double> _weights = [5, 8, 2, 13];

  static final List<Color> _colors = [
    AppColors.period,
    AppColors.fertile,
    AppColors.ovulation,
    AppColors.luteal,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 3.5;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const stroke = 15.0;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = (isDark ? Colors.white : AppColors.textPrimary)
          .withValues(alpha: 0.07);
    canvas.drawCircle(center, radius, track);

    _paintHalo(canvas, center, radius);

    const startBase = -math.pi / 2;
    const fullSweep = 2 * math.pi;
    const gap = 0.11;
    final total = _weights.reduce((a, b) => a + b);

    var consumed = 0.0;
    for (var i = 0; i < _weights.length; i++) {
      final segment = _weights[i] / total;
      final within = ((draw - consumed) / segment).clamp(0.0, 1.0);
      if (within > 0) {
        final from = startBase + consumed * fullSweep + gap;
        final to = startBase + (consumed + segment) * fullSweep - gap;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = _colors[i];
        canvas.drawArc(rect, from, (to - from) * within, false, paint);
      }
      consumed += segment;
    }
  }

  void _paintHalo(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.16);

    const count = 64;
    final tickRadius = radius + 15;
    final rotation = spin * 2 * math.pi;
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + rotation;
      final length = i % 4 == 0 ? 6.0 : 3.0;
      final outer = Offset(
        center.dx + math.cos(angle) * tickRadius,
        center.dy + math.sin(angle) * tickRadius,
      );
      final inner = Offset(
        center.dx + math.cos(angle) * (tickRadius - length),
        center.dy + math.sin(angle) * (tickRadius - length),
      );
      canvas.drawLine(inner, outer, paint);
    }
  }

  @override
  bool shouldRepaint(_CycleRingPainter oldDelegate) =>
      oldDelegate.draw != draw ||
      oldDelegate.spin != spin ||
      oldDelegate.isDark != isDark;
}
