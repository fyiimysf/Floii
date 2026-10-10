import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:floi/utils/extensions/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/cycle_models.dart';
import '../../../services/cycle/phase_service.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/dimensions.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/common/cards.dart';

/// Dashboard hero for Insights: a gradient "now" header with a progress ring,
/// the two next milestones (period + ovulation) and a phase timeline — bolder,
/// more spacious take on the dashboard card rather than a copy of it.
class CycleNowCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<PhaseDetail> phases;
  final DateTime cycleStart;
  final String currentPhase;
  final String phaseHint;
  final Color phaseColor;
  final DateTime? prediction;
  final int? cycleDay;

  const CycleNowCard({
    super.key,
    required this.stats,
    required this.phases,
    required this.cycleStart,
    required this.currentPhase,
    required this.phaseHint,
    required this.phaseColor,
    this.prediction,
    this.cycleDay,
  });

  int get _totalDays => phases.isNotEmpty
      ? phases.last.endDate.difference(cycleStart).inDays + 1
      : (stats['average'] as int? ?? 28);

  double get _progress =>
      cycleDay == null ? 0.0 : (((cycleDay! - 1) / _totalDays).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periods = (stats['periods'] as List<List<DateTime>>?) ?? [];

    if (periods.isEmpty) return _buildEmptyState(context);

    final today = DateTime.now();
    final ovulation = stats['ovulationDate'] as DateTime?;

    final daysUntil = prediction != null
        ? DateTime(prediction!.year, prediction!.month, prediction!.day)
            .difference(DateTime(today.year, today.month, today.day))
            .inDays
        : null;
    final daysToOvulation = ovulation != null
        ? DateTime(ovulation.year, ovulation.month, ovulation.day)
            .difference(DateTime(today.year, today.month, today.day))
            .inDays
        : null;

    return Container(
      padding: EdgeInsets.all(
        context.scaleLength(AppDimensions.cardPadding),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            phaseColor.withValues(alpha: 0.16),
            theme.colorScheme.surface.withValues(alpha: 0),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: context.scaleLength(52),
                height: context.scaleLength(52),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      phaseColor.withValues(alpha: 0.24),
                      phaseColor.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                child: Icon(
                  PhaseService.getPhaseIcon(currentPhase),
                  color: phaseColor,
                  size: context.scaleLength(AppDimensions.iconLarge),
                ),
              ),
              SizedBox(
                  width: context.scaleLength(AppDimensions.elementSpacing)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scales down rather than clipping when the hero row runs out of room.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.tr('currentPhase').toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: phaseColor.withValues(alpha: 0.8),
                          fontSize: 11,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Scales down rather than clipping when the hero row runs out of room.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        currentPhase,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: phaseColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.scaleLength(AppDimensions.smallSpacing)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.scaleLength(
                    AppDimensions.elementSpacing,
                  ),
                  vertical: context.scaleLength(AppDimensions.smallSpacing),
                ),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                  border: Border.all(color: phaseColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  cycleDay != null ? '${context.tr('Day')} $cycleDay' : '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: phaseColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: context.scaleLength(AppDimensions.elementSpacing + 4),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProgressRing(
                progress: _progress,
                color: phaseColor,
                day: cycleDay ?? 1,
                total: _totalDays,
              ),
              SizedBox(
                width: context.scaleLength(AppDimensions.elementSpacing + 4),
              ),
              Expanded(
                child: Column(
                  children: [
                    _MilestoneBlock(
                      icon: Icons.event_outlined,
                      label: context.tr('nextPeriod'),
                      value: daysUntil != null
                          ? daysUntil <= 0
                              ? context.tr('today')
                              : '$daysUntil ${context.tr('days')}'
                          : '—',
                      detail: prediction != null
                          ? DateFormat('d MMM').format(prediction!)
                          : null,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppDimensions.elementSpacing),
                    _MilestoneBlock(
                      icon: Icons.wb_sunny_outlined,
                      label: context.tr('ovulationPhase'),
                      value: daysToOvulation != null
                          ? daysToOvulation <= 0
                              ? context.tr('today')
                              : '$daysToOvulation ${context.tr('days')}'
                          : '—',
                      detail: ovulation != null
                          ? DateFormat('d MMM').format(ovulation)
                          : null,
                      color: AppColors.ovulation,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.elementSpacing + 4),
          if (phases.isNotEmpty)
            _buildPhaseTrack(theme)
          else
            _buildEmptyTrack(theme),
          const SizedBox(height: AppDimensions.smallSpacing + 2),
          // Scales down instead of clipping the "Day X of Y · date" summary.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              cycleDay != null
                  ? '${context.tr('Day')} $cycleDay ${context.tr('of')} '
                      '$_totalDays · ${DateFormat('MMM d').format(cycleStart)}'
                  : DateFormat('MMM d').format(cycleStart),
              maxLines: 1,
              softWrap: false,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.smallSpacing + 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.tinySpacing + 2),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  size: AppDimensions.iconSmall,
                  color: phaseColor,
                ),
              ),
              const SizedBox(width: AppDimensions.smallSpacing),
              Expanded(
                child: Text(
                  phaseHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseTrack(ThemeData theme) {
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: 16,
            child: Stack(
              alignment: AlignmentDirectional.centerStart,
              children: [
                Row(
                  children: [
                    for (final phase in phases)
                      Expanded(
                        flex: phase.duration < 1 ? 1 : phase.duration,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: PhaseService.getPhaseColor(phase.name)
                                  .withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Align(
                  alignment: Alignment(-1 + 2 * _progress, 0),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surface,
                      border: Border.all(color: phaseColor, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: phaseColor.withValues(alpha: 0.4),
                          blurRadius: 5,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyTrack(ThemeData theme) {
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return ClayCard(
      entranceStep: 0,
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.elementSpacing),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today,
              color: AppColors.primary,
              size: AppDimensions.iconLarge,
            ),
          ),
          const SizedBox(width: AppDimensions.elementSpacing),
          Expanded(
            child: Text(
              context.tr('trackPeriodHint'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  final Color color;
  final int day;
  final int total;

  const _ProgressRing({
    required this.progress,
    required this.color,
    required this.day,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diameter = context.scaleLength(108, min: 0.72);
    final stroke = context.scaleLength(10, min: 0.72);
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(diameter, diameter),
            painter: _RingPainter(
              progress: progress,
              color: color,
              strokeWidth: stroke,
              trackColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$day',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: color,
                    fontSize: context.scaleLength(34),
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.trArgs('dayOfCycle', {'total': total}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = strokeWidth;
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - stroke / 2 - 4;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress > 0.003) {
      final sweep = 2 * math.pi * progress;
      final start = -math.pi / 2;

      final gradientPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader =
            ui.Gradient.sweep(center, [color.withValues(alpha: 0.45), color]);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
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
        start,
        sweep,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor;
  }
}

class _MilestoneBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final Color color;

  const _MilestoneBlock({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.elementSpacing,
        vertical: AppDimensions.smallSpacing + 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.smallSpacing),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: AppDimensions.iconSmall + 2, color: color),
          ),
          const SizedBox(width: AppDimensions.smallSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                // Scales down instead of clipping when the progress ring takes up most of
                // the hero row.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (detail != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          detail!,
                          maxLines: 1,
                          softWrap: false,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
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
