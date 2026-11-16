import 'package:floi/utils/extensions/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../services/cycle/phase_service.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/dimensions.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/common/section_header.dart';

/// 7-day lookahead as part of the insights dashboard: each day is tinted by its
/// predicted phase / fertility status, so the upcoming window is legible at a
/// glance. Content block only — the dashboard surface provides the card.
class WeekForecastCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const WeekForecastCard({super.key, required this.stats});

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final periods = (stats['periods'] as List<List<DateTime>>? ?? []);
    final fertileStart = stats['fertileWindowStart'] as DateTime?;
    final fertileEnd = stats['fertileWindowEnd'] as DateTime?;
    final ovulation = stats['ovulationDate'] as DateTime?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: context.tr('forecast7'),
          icon: HugeIcons.strokeRoundedChartLineData01,
          caption: context.tr('predicted'),
        ),
        const SizedBox(height: AppDimensions.elementSpacing),
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _DayTile(
                    date: today.add(Duration(days: i)),
                    weekday:
                        _weekdays[today.add(Duration(days: i)).weekday - 1],
                    color: _colorFor(
                      today.add(Duration(days: i)),
                      periods: periods,
                      fertileStart: fertileStart,
                      fertileEnd: fertileEnd,
                      ovulation: ovulation,
                    ),
                    isToday: i == 0,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.elementSpacing),
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          // Wrap instead of a three-way Row so longer legend labels stack
          // onto a second row on narrow screens rather than being clipped.
          child: Wrap(
            spacing: AppDimensions.smallSpacing,
            runSpacing: AppDimensions.tinySpacing,
            children: [
              _LegendChip(
                color: AppColors.period,
                label: context.tr('period'),
              ),
              _LegendChip(
                color: AppColors.fertile,
                label: context.tr('fertile'),
              ),
              _LegendChip(
                color: AppColors.ovulation,
                label: context.tr('ovulationPhase'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _colorFor(
    DateTime date, {
    required List<List<DateTime>> periods,
    required DateTime? fertileStart,
    required DateTime? fertileEnd,
    required DateTime? ovulation,
  }) {
    for (final p in periods) {
      final a = DateTime(p.first.year, p.first.month, p.first.day);
      final b = DateTime(p.last.year, p.last.month, p.last.day);
      if (!date.isBefore(a) && !date.isAfter(b)) return AppColors.period;
    }
    if (ovulation != null &&
        date.year == ovulation.year &&
        date.month == ovulation.month &&
        date.day == ovulation.day) {
      return AppColors.ovulation;
    }
    if (fertileStart != null &&
        fertileEnd != null &&
        !date.isBefore(fertileStart) &&
        !date.isAfter(fertileEnd)) {
      return AppColors.fertile;
    }
    return PhaseService.getPhaseColor(PhaseService.getPhase(date, stats).name);
  }
}

class _DayTile extends StatelessWidget {
  final DateTime date;
  final String weekday;
  final Color color;
  final bool isToday;

  const _DayTile({
    required this.date,
    required this.weekday,
    required this.color,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final circleColor = isToday
        ? color.withValues(alpha: 0.16)
        : theme.colorScheme.onSurface.withValues(alpha: 0.04);
    // Seven fixed-width circles squeeze the row on a narrow phone, so the
    // day bubble shrinks with the screen instead of overflowing its column.
    final diameter = context.scaleLength(34, min: 0.76);
    final dot = context.scaleLength(6, min: 0.8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          weekday,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isToday
                ? color
                : theme.colorScheme.onSurface.withValues(alpha: 0.45),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimensions.tinySpacing + 2),
        Container(
          width: diameter,
          height: diameter,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleColor,
            gradient: isToday
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.3),
                      color.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            border: Border.all(
              color: isToday ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${date.day}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: isToday ? color : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.tinySpacing + 3),
        Container(
          width: dot,
          height: dot,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.smallSpacing + 2,
        vertical: AppDimensions.tinySpacing + 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: AppDimensions.smallSpacing),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
