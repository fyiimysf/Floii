import 'package:floi/utils/extensions/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/enums.dart';
import '../../../services/cycle/cycle_calculation_service.dart';
import '../../../services/cycle/phase_service.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/dimensions.dart';
import '../../../widgets/common/cards.dart';
import '../../../widgets/common/metric_tile.dart';
import '../../../widgets/common/semi_donut_chart.dart';
import 'cycle_phase_strip.dart';

class CycleStatusCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  final VoidCallback? onTap;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;

  /// Mood already logged for today, shown inside the mood button so the current
  /// selection is visible from the card itself.
  final Mood? currentMood;

  /// Opens the mood picker sheet. When null the mood button is hidden.
  final VoidCallback? onMoodTap;

  const CycleStatusCard({
    super.key,
    required this.stats,
    this.onTap,
    this.collapsed = false,
    this.onToggleCollapsed,
    this.currentMood,
    this.onMoodTap,
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

    if (collapsed) {
      return _buildCollapsed(
        context,
        phaseColor: phaseColor,
        phaseLabel: phaseLabel,
        cycleDay: cycleDay,
        total: total,
      );
    }

    return ClayCard(
      entranceStep: 0,
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.elementSpacing),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.smallSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SemiDonutChart(
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
                        child: MetricTile(
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
                        child: MetricTile(
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
                        child: MetricTile(
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
          // Collapse hugs the left edge, mood mirrors it on the right.
          if (onToggleCollapsed != null)
            Positioned(
              top: 0,
              left: 0,
              child: IconButton(
                onPressed: onToggleCollapsed,
                tooltip: context.tr('collapse'),
                style: IconButton.styleFrom(
                  backgroundColor: phaseColor.withValues(alpha: 0.1),
                ),
                icon: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: phaseColor,
                  size: AppDimensions.iconLarge,
                ),
              ),
            ),
          if (onMoodTap != null)
            Positioned(
              top: 0,
              right: 0,
              child: _MoodButton(
                currentMood: currentMood,
                onTap: onMoodTap!,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsed(
    BuildContext context, {
    required Color phaseColor,
    required String phaseLabel,
    required int cycleDay,
    required int total,
  }) {
    final theme = Theme.of(context);

    return ClayCard(
      entranceStep: 0,
      onTap: onToggleCollapsed,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.elementSpacing,
        vertical: AppDimensions.smallSpacing + 4,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onToggleCollapsed,
            tooltip: context.tr('expand'),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: phaseColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.water_drop,
              color: phaseColor,
              size: AppDimensions.iconLarge,
            ),
          ),
          const SizedBox(width: AppDimensions.elementSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phaseLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: phaseColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.trArgs('cycleDay', {'day': cycleDay, 'total': total}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onMoodTap != null)
            _MoodButton(
              currentMood: currentMood,
              onTap: onMoodTap!,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return ClayCard(
      entranceStep: 0,
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      child: Stack(
        children: [
          Column(
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppDimensions.sectionSpacing),
              Container(
                padding: const EdgeInsets.all(AppDimensions.elementSpacing),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
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
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // No collapse control in this state, so the mood button takes the mirrored
          // top-right corner: logging a mood works before the first period.
          if (onMoodTap != null)
            Positioned(
              top: 0,
              right: 0,
              child: _MoodButton(
                currentMood: currentMood,
                onTap: onMoodTap!,
              ),
            ),
        ],
      ),
    );
  }
}

/// Opens the mood picker. Styled to match the collapse control: a tinted circle
/// with the accent icon, showing the mood logged today once there is one.
///
/// Both states build one [Icon] with the same size and colour, so the button
/// cannot restyle or resize once a mood is set. An earlier version used a
/// [Text] holding the mood's emoji, which sized itself from the glyph's metrics
/// instead of the icon slot and so drew smaller and shifted the button.
class _MoodButton extends StatelessWidget {
  final Mood? currentMood;
  final VoidCallback onTap;

  const _MoodButton({
    required this.currentMood,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: context.tr('howFeelingToday'),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
      ),
      icon: Icon(
        currentMood?.icon ?? Icons.mood_outlined,
        color: AppColors.secondary,
        size: AppDimensions.iconLarge,
      ),
    );
  }
}
