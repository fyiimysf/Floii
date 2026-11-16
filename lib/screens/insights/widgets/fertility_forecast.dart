import 'package:floi/utils/extensions/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import '../../../services/cycle/prediction_service.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/dimensions.dart';
import '../../../utils/extensions/date_extensions.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/common/section_header.dart';

/// Fertility outlook as part of the insights dashboard: the fertile window and
/// ovulation date as two summary cells plus a connected day strip of the
/// window. Content block only — the surface provides the card.
class FertilityForecast extends StatelessWidget {
  final DateTime prediction;

  const FertilityForecast({
    super.key,
    required this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fertileDates = PredictionService.predictFertileWindow(prediction);
    final ovulationDate = PredictionService.predictOvulation(prediction);
    final first = fertileDates.isNotEmpty ? fertileDates.first : ovulationDate;
    final last = fertileDates.isNotEmpty ? fertileDates.last : ovulationDate;

    final cells = [
      _FertilityCell(
        label: context.tr('fertile'),
        value:
            '${DateFormat('MMM d').format(first)} – ${DateFormat('MMM d').format(last)}',
        color: AppColors.fertile,
        icon: Icons.spa_outlined,
      ),
      _FertilityCell(
        label: context.tr('ovulationPhase'),
        value: DateFormat('MMM d').format(ovulationDate),
        color: AppColors.ovulation,
        icon: Icons.wb_sunny,
      ),
    ];

    // "Sep 20 – Sep 26" needs the full card width to read cleanly, so on a
    // narrow phone the two summary cells stack instead of sharing a row.
    final isCompact = context.isCompactScreen;
    final dayDiameter = context.scaleLength(44, min: 0.76);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: context.tr('fertForcast'),
          icon: HugeIcons.strokeRoundedSun03,
          caption: context.tr('fertileWindow'),
        ),
        const SizedBox(height: AppDimensions.elementSpacing),
        if (isCompact)
          Column(
            children: [
              cells[0],
              const SizedBox(height: AppDimensions.smallSpacing),
              cells[1],
            ],
          )
        else
          Row(
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0) const SizedBox(width: AppDimensions.elementSpacing),
                Expanded(child: cells[i]),
              ],
            ],
          ),
        const SizedBox(height: AppDimensions.elementSpacing),
        SizedBox(
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 18,
                right: 18,
                top: 29,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.fertile.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              Positioned.fill(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: fertileDates.length,
                  separatorBuilder: (_, index) =>
                      const SizedBox(width: AppDimensions.smallSpacing),
                  itemBuilder: (context, index) {
                    final date = fertileDates[index];
                    final isOvulation = date.isSameDate(ovulationDate);
                    return Container(
                      width: dayDiameter,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOvulation
                            ? AppColors.ovulation
                            : theme.colorScheme.surface,
                        border: Border.all(
                          color: isOvulation
                              ? AppColors.ovulation
                              : AppColors.fertile,
                          width: 1.6,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${date.day}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color:
                                isOvulation ? Colors.white : AppColors.fertile,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FertilityCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _FertilityCell({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.elementSpacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppDimensions.iconSmall, color: color),
              const SizedBox(width: AppDimensions.tinySpacing),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.tinySpacing),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
