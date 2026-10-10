// lib/screens/insights/widgets/statistics_grid.dart

import 'dart:math' as math;

import 'package:floi/utils/extensions/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../services/cycle/cycle_analytics_service.dart';
import '../../../services/cycle/cycle_calculation_service.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/dimensions.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/common/section_header.dart';

/// Dense grid of cycle metrics inside one card: averages, spread and
/// regularity — the numbers that actually explain a cycle at a glance.
/// Two columns on narrow screens, three once the tiles have room.
class StatisticsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;

  const StatisticsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final periods = stats['periods'] as List<List<DateTime>>? ?? [];
    final isCompact = context.isCompactScreen;

    final analytics =
        CycleAnalyticsService.computeAnalyticsFromPeriods(periods);
    final cycleLengths =
        (analytics['cycleLengths'] as List<dynamic>? ?? const <int>[])
            .cast<int>();

    final hasCycles = cycleLengths.length > 1;

    final avgCycle = (analytics['averageCycle'] as double?)?.round() ??
        (stats['average'] as int? ?? 28);
    final avgPeriod = (analytics['averagePeriod'] as double?)?.round() ??
        (stats['currentPeriodLength'] as int? ?? 5);
    final median = (analytics['medianCycle'] as double?)?.round();
    final minCycle = analytics['minCycle'] as int?;
    final maxCycle = analytics['maxCycle'] as int?;
    final count = (analytics['count'] as int?) ?? periods.length;
    final consistency = hasCycles
        ? ((analytics['consistency'] as int?) ??
            CycleCalculationService.calculateConsistency(cycleLengths))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: context.tr('stats'),
          icon: HugeIcons.strokeRoundedAnalytics02,
          caption: hasCycles ? context.tr('cycleTrendCaption') : null,
        ),
        const SizedBox(height: AppDimensions.elementSpacing),
        if (hasCycles) ...[
          _CycleBarsChart(
            values: cycleLengths.length > 12
                ? cycleLengths.sublist(cycleLengths.length - 12)
                : cycleLengths,
            average: avgCycle.toDouble(),
          ),
          const SizedBox(height: AppDimensions.smallSpacing),
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            // A Wrap lets the legend chips flow onto a second row instead of
            // forcing three labels into thirds of a narrow screen.
            child: Wrap(
              spacing: AppDimensions.elementSpacing,
              runSpacing: AppDimensions.tinySpacing,
              children: [
                _ChartLegend(
                  color: AppColors.primary,
                  label: '${context.tr('latest')} ${cycleLengths.last}',
                ),
                _ChartLegend(
                  color: AppColors.secondary,
                  dashed: true,
                  label: '${context.tr('averageCycle')} $avgCycle',
                ),
                if (minCycle != null && maxCycle != null)
                  _ChartLegend(
                    color: AppColors.mint,
                    label: '$minCycle–$maxCycle',
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.elementSpacing),
        ],
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              // Two-up on narrow phones, three across once the tiles are
              // wide enough to read as inline rows.
              crossAxisCount: context.screenSize.gridColumns,
              // Narrow screens get taller tiles because their labels wrap to
              // a second line instead of being clipped.
              mainAxisExtent: isCompact ? 86 : 76,
              mainAxisSpacing: AppDimensions.smallSpacing,
              crossAxisSpacing: AppDimensions.elementSpacing,
            ),
            children: [
              _MetricTile(
                label: context.tr('averageCycle'),
                value: '$avgCycle',
                suffix: context.tr('days'),
                compact: isCompact,
              ),
              _MetricTile(
                label: context.tr('avgPeriod'),
                value: '$avgPeriod',
                suffix: context.tr('days'),
                compact: isCompact,
              ),
              _MetricTile(
                label: context.tr('medianCycle'),
                value: median?.toString() ?? '--',
                suffix: median != null ? context.tr('days') : null,
                compact: isCompact,
              ),
              _MetricTile(
                label: context.tr('cycleConsistency'),
                value: consistency?.toString() ?? '--',
                suffix: consistency != null ? '%' : null,
                compact: isCompact,
              ),
              _MetricTile(
                label: context.tr('periodsLogged'),
                value: '$count',
                compact: isCompact,
              ),
              _MetricTile(
                label: context.tr('cycleRange'),
                value: (hasCycles && minCycle != null && maxCycle != null)
                    ? '$minCycle–$maxCycle'
                    : '--',
                suffix: hasCycles ? context.tr('days') : null,
                compact: isCompact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;

  /// Narrow-screen variant: the label is allowed to wrap instead of being
  /// clipped to an ellipsis, and the padding tightens to buy the extra line.
  final bool compact;

  const _MetricTile({
    required this.label,
    required this.value,
    this.suffix,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact
            ? AppDimensions.smallSpacing + 2
            : AppDimensions.elementSpacing,
        vertical: AppDimensions.smallSpacing,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: compact ? 2 : 1,
                softWrap: !compact,
                overflow: compact ? TextOverflow.ellipsis : null,
                style:
                    compact ? labelStyle?.copyWith(height: 1.15) : labelStyle,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.tinySpacing),
          // The value is the priority; if value + unit cannot both fit the tile,
          // the pair scales down rather than either half getting clipped.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  softWrap: false,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 3),
                  Text(
                    suffix!,
                    maxLines: 1,
                    softWrap: false,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact bar chart of recent cycle lengths with the average reference line,
/// so the "spread" behind the numbers is visible at a glance.
class _CycleBarsChart extends StatelessWidget {
  final List<int> values;
  final double average;

  const _CycleBarsChart({
    required this.values,
    required this.average,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, double.infinity),
        painter: _BarChartPainter(
          values: values,
          average: average,
          barColor: AppColors.primary,
          avgColor: AppColors.secondary,
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<int> values;
  final double average;
  final Color barColor;
  final Color avgColor;

  _BarChartPainter({
    required this.values,
    required this.average,
    required this.barColor,
    required this.avgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padTop = 10.0;
    const padBottom = 6.0;
    const padLeft = 8.0;
    const padRight = 8.0;
    final innerW = size.width - padLeft - padRight;
    final innerH = size.height - padTop - padBottom;

    if (values.isEmpty || innerW <= 0 || innerH <= 0) return;

    var minV = math.min(values.reduce(math.min), average);
    var maxV = math.max(values.reduce(math.max), average);
    if (maxV - minV < 1) {
      maxV += 1;
      minV -= 1;
    }
    final range = maxV - minV;

    double yFor(double v) => padTop + (1 - (v - minV) / range) * innerH;

    final avgY = yFor(average);
    _drawDashedLine(
      canvas,
      Offset(padLeft, avgY),
      Offset(size.width - padRight, avgY),
      Paint()
        ..color = avgColor.withValues(alpha: 0.8)
        ..strokeWidth = 1.2,
    );

    final n = values.length;
    final slotW = innerW / n;
    final barW = (slotW * 0.56).clamp(4.0, 34.0);
    final radius = Radius.circular(math.min(barW / 2, 5));

    for (var i = 0; i < n; i++) {
      final v = values[i].toDouble();
      final x0 = padLeft + slotW * i + (slotW - barW) / 2;
      final yTop = yFor(v);
      final h = innerH - (yTop - padTop);
      final isLatest = i == n - 1;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x0, yTop, barW, h),
        topLeft: radius,
        topRight: radius,
      );
      canvas.drawRRect(
        rect,
        Paint()..color = isLatest ? barColor : barColor.withValues(alpha: 0.32),
      );
      if (isLatest) {
        canvas.drawCircle(
          Offset(x0 + barW / 2, yTop),
          3,
          Paint()..color = barColor,
        );
      }
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint paint, {
    double dash = 4,
    double gap = 4,
  }) {
    const tiny = 1e-4;
    if ((b.dx - a.dx).abs() < tiny) return;
    var x = a.dx;
    while (x < b.dx) {
      final end = math.min(x + dash, b.dx);
      canvas.drawLine(Offset(x, a.dy), Offset(end, a.dy), paint);
      x = end + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.average != average ||
        oldDelegate.barColor != barColor;
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _ChartLegend({
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
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
