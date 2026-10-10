import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:floi/utils/extensions/localization_extension.dart';
import 'package:flutter/material.dart';
import '../../utils/constants/dimensions.dart';

/// Hero progress chart: a gradient semi-donut that frames the cycle phase
/// headline (day ordinal, phase name and hint) like the dashboard card.
class SemiDonutChart extends StatelessWidget {
  final int day;
  final int total;
  final double progress;
  final Color color;
  final String heading;
  final String title;
  final String subtitle;

  const SemiDonutChart({
    super.key,
    required this.day,
    required this.total,
    required this.progress,
    required this.color,
    required this.heading,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = (width * 0.52).clamp(160.0, 220.0);

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _SemiDonutPainter(
                    progress: progress,
                    color: color,
                    trackColor:
                        theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: width * 0.84,
                  height: (width / 2 - 36).clamp(70.0, 210.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _ordinal(day),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: color,
                            fontSize: 38,
                            height: 1.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.trArgs('dayOfCycle', {'total': total}),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.smallSpacing + 4),
                        Text(
                          heading,
                          maxLines: 1,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color.withValues(alpha: 0.8),
                            fontSize: 11,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _ordinal(int n) {
    final mod = n % 100;
    if (mod >= 11 && mod <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }
}

class _SemiDonutPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _SemiDonutPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 14.0;
    final radius = size.width / 2 - stroke / 2 - 6;
    final center = Offset(size.width / 2, size.height - stroke / 2 - 6);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      track,
    );

    if (progress > 0.003) {
      final sweep = math.pi * progress;
      final gradientPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2 - radius, center.dy),
          Offset(size.width / 2 + radius, center.dy),
          [color.withValues(alpha: 0.45), color],
        );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        sweep,
        false,
        gradientPaint,
      );

      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        sweep,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SemiDonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
