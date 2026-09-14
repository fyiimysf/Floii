import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:floi/utils/extensions/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/cycle/cycle_calculation_service.dart';
import '../../../services/cycle/phase_service.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/dimensions.dart';
import '../../../widgets/common/cards.dart';
import 'cycle_phase_strip.dart';

class CycleStatusCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  final VoidCallback? onTap;

  const CycleStatusCard({
    super.key,
    required this.stats,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final periods = (stats['periods'] as List<List<DateTime>>?) ?? [];

    if (periods.isEmpty) {
      return _buildEmptyState(context);
    }

    final phaseName = PhaseService.getPhaseName(DateTime.now(), stats);
    final phaseColor = PhaseService.getPhaseColor(phaseName);
    final phaseLabel = context.tr('${phaseName.toLowerCase()}Phase');
    final phaseHint = context.tr('${phaseName.toLowerCase()}Hint');

    final total = stats['average'] as int? ?? 28;
    final cycleDay = CycleCalculationService.getCurrentCycleDay(
          periods,
          averageCycleLength: total,
        ) ??
        DateTime.now().difference(periods.last.first).inDays + 1;
    final progress = (cycleDay / total).clamp(0.0, 1.0);

    final prediction = stats['prediction'] as DateTime?;
    final ovulation = stats['ovulationDate'] as DateTime?;
    final today = DateTime.now();
    final daysUntil = prediction != null
        ? DateTime(prediction.year, prediction.month, prediction.day)
            .difference(DateTime(today.year, today.month, today.day))
            .inDays
        : null;
    final daysToOvulation = ovulation != null
        ? DateTime(ovulation.year, ovulation.month, ovulation.day)
            .difference(DateTime(today.year, today.month, today.day))
            .inDays
        : null;

    final cycleLengths = stats['cycleLengths'] as List<int>? ?? [];
    final consistency = cycleLengths.isEmpty
        ? null
        : CycleCalculationService.calculateConsistency(cycleLengths);

    return ClayCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.elementSpacing),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.smallSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SemiDonutChart(
              day: cycleDay,
              total: total,
              progress: progress,
              color: phaseColor,
              heading: context.tr('currentPhase').toUpperCase(),
              title: phaseLabel,
              subtitle: phaseHint,
            ),
            const SizedBox(height: AppDimensions.elementSpacing + 2),
            Divider(
              height: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            ),
            const SizedBox(height: AppDimensions.elementSpacing),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 210,
                    child: _MetricTile(
                      icon: Icons.event_outlined,
                      value: daysUntil != null
                          ? daysUntil <= 0
                              ? context.tr('today')
                              : '$daysUntil ${context.tr('days')}'
                          : '—',
                      detail: prediction != null
                          ? DateFormat('d MMM').format(prediction)
                          : null,
                      label: context.tr('nextPeriod'),
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.smallSpacing),
                  SizedBox(
                    width: 210,
                    child: _MetricTile(
                      icon: Icons.wb_sunny_outlined,
                      value: daysToOvulation != null
                          ? daysToOvulation <= 0
                              ? context.tr('today')
                              : '$daysToOvulation ${context.tr('days')}'
                          : '—',
                      detail: ovulation != null
                          ? DateFormat('d MMM').format(ovulation)
                          : null,
                      label: context.tr('ovulationPhase'),
                      color: AppColors.ovulation,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.smallSpacing),
                  SizedBox(
                    width: 210,
                    child: _MetricTile(
                      icon: Icons.analytics_outlined,
                      value: consistency != null ? '$consistency%' : '—',
                      label: context.tr('consistency'),
                      color: AppColors.mint,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.smallSpacing),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.elementSpacing + 2),
            CyclePhaseStrip(stats: stats),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return ClayCard(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.elementSpacing),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today,
              color: AppColors.primary,
              size: AppDimensions.iconXL,
            ),
          ),
          const SizedBox(height: AppDimensions.elementSpacing),
          Text(
            context.tr('welcomeTitle'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppDimensions.smallSpacing),
          Text(
            context.tr('welcomeSubtitle'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppDimensions.sectionSpacing),
          Container(
            padding: const EdgeInsets.all(AppDimensions.elementSpacing),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: AppDimensions.iconMedium,
                ),
                const SizedBox(width: AppDimensions.elementSpacing),
                Expanded(
                  child: Text(
                    context.tr('welcomeHint'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SemiDonutChart extends StatelessWidget {
  final int day;
  final int total;
  final double progress;
  final Color color;
  final String heading;
  final String title;
  final String subtitle;

  const _SemiDonutChart({
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

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? detail;
  final String label;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.elementSpacing,
        vertical: AppDimensions.smallSpacing + 2,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.smallSpacing),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: AppDimensions.iconMedium, color: color),
          ),
          const SizedBox(width: AppDimensions.elementSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        detail!,
                        maxLines: 1,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
