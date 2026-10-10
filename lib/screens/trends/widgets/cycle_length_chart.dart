import 'package:hugeicons/hugeicons.dart';
// lib/screens/trends/widgets/cycle_length_chart.dart

import 'package:floi/utils/extensions/localization_extension.dart';
import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/dimensions.dart';

/// Shows cycle-length drift over the last few cycles as an annotated
/// sparkline with the average reference line.
class CycleLengthChart extends StatelessWidget {
  final Map<String, dynamic> trends;
  final double? averageCycle;

  const CycleLengthChart({
    super.key,
    required this.trends,
    this.averageCycle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final series = (trends['cycleSeries'] as List<dynamic>? ?? [])
        .map((e) => (e as ({DateTime start, double value})).value)
        .toList();
    final values = series;

    final avg =
        averageCycle ?? (trends['avgCycle'] as num?)?.toDouble() ?? 28.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                padding: const EdgeInsets.all(AppDimensions.elementSpacing),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedChartIncrease,
                  color: theme.colorScheme.primary,
                  size: AppDimensions.iconMedium,
                )),
            const SizedBox(width: AppDimensions.elementSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('cycleTrend'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    context.tr('cycleTrendCaption'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.smallSpacing),
            _LegendDot(
              color: theme.colorScheme.primary,
              label: context.tr('yourCycle'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.elementSpacing),
        Text(
          '${values.isEmpty ? 0 : values.last.round()} ${context.tr('days')}',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppDimensions.smallSpacing),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrendPainter(
                values: values,
                average: avg,
                lineColor: theme.colorScheme.primary,
                avgColor: AppColors.secondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.smallSpacing),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.tr('earliest'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.smallSpacing),
              child: _LegendDot(
                color: AppColors.secondary,
                label: '${context.tr('averageCycle')} ${avg.round()}',
                dashed: true,
              ),
            ),
            Expanded(
              child: Text(
                context.tr('latest'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> values;
  final double average;
  final Color lineColor;
  final Color avgColor;

  _TrendPainter({
    required this.values,
    required this.average,
    required this.lineColor,
    required this.avgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pad = 8.0;
    final innerHeight = size.height - pad * 2;

    var minV = average;
    var maxV = average;
    for (final v in values) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final range = (maxV - minV).abs() < 0.001 ? 4.0 : (maxV - minV).abs();

    double yFor(double value) =>
        pad + (1 - ((value - minV) / range)) * innerHeight;

    final avgY = yFor(average);
    canvas.drawLine(
      Offset(0, avgY),
      Offset(size.width, avgY),
      Paint()
        ..color = avgColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    if (values.length >= 2) {
      final dx = size.width / (values.length - 1);
      final path = Path();
      for (int i = 0; i < values.length; i++) {
        final x = i * dx;
        final y = yFor(values[i]);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      final shader = LinearGradient(
        colors: [lineColor.withValues(alpha: 0.4), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, Paint()..shader = shader);

      canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      final last = Offset(size.width, yFor(values.last));
      canvas.drawCircle(last, 5, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.average != average;
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendDot({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dashed ? 14 : 8,
          height: dashed ? 1.5 : 8,
          decoration: BoxDecoration(
            color: dashed ? color : null,
            shape: dashed ? BoxShape.rectangle : BoxShape.circle,
            border: dashed ? Border.all(color: color, width: 1) : null,
          ),
        ),
        const SizedBox(width: AppDimensions.tinySpacing),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
