import 'package:floi/utils/extensions/localization_extension.dart';
import 'package:flutter/material.dart';
import '../../models/cycle_models.dart';
import '../../services/cycle/phase_service.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import 'cards.dart';

class PhaseCard extends StatelessWidget {
  final PhaseDetail phase;
  final bool isCurrent;
  final bool isCompleted;

  const PhaseCard({
    super.key,
    required this.phase,
    this.isCurrent = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = PhaseService.getPhaseColor(phase.name);
    final progress = PhaseService.calculatePhaseProgress(phase);

    return ClayCard(
      color: isCurrent ? color.withOpacity(0.1) : null,
      radius: AppDimensions.radiusMedium,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.smallSpacing,
        vertical: AppDimensions.elementSpacing,
      ),
      shadows: isDark || isCompleted
          ? []
          : [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.smallSpacing),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? theme.colorScheme.onSurface.withOpacity(0.06)
                      : color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      PhaseService.getPhaseIcon(phase.name),
                      color: isCompleted
                          ? theme.colorScheme.onSurface.withOpacity(0.35)
                          : color,
                      size: AppDimensions.iconLarge,
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.tinySpacing),
          Text(
            phase.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: isCompleted
                  ? theme.colorScheme.onSurface.withOpacity(0.45)
                  : color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.tinySpacing),
          if (isCurrent)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.elementSpacing,
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSmall),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor:
                          theme.colorScheme.onSurface.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.tinySpacing),
                  Text(
                    '${phase.duration} ${context.tr('days')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              '${phase.duration} ${context.tr('days')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isCompleted
                    ? theme.colorScheme.onSurface.withOpacity(0.35)
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
        ],
      ),
    );
  }
}

class PhaseRow extends StatelessWidget {
  final PhaseDetail phase;

  const PhaseRow({
    super.key,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = PhaseService.getPhaseColor(phase.name);

    return ClayCard(
      color: color.withOpacity(0.03),
      radius: AppDimensions.radiusMedium,
      padding: const EdgeInsets.all(AppDimensions.elementSpacing),
      shadows: isDark
          ? []
          : [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
      child: Row(
        children: [
          Container(
            width: 5,
            height: 45,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.elementSpacing),
          Container(
            padding: const EdgeInsets.all(AppDimensions.smallSpacing),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhaseService.getPhaseIcon(phase.name),
              color: color,
              size: AppDimensions.iconSmall,
            ),
          ),
          const SizedBox(width: AppDimensions.elementSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.tinySpacing),
                Text(
                  '${_formatDate(phase.startDate)} - ${_formatDate(phase.endDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.elementSpacing,
              vertical: AppDimensions.smallSpacing,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusCircular),
            ),
            child: Text(
              '${phase.duration} days',
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
