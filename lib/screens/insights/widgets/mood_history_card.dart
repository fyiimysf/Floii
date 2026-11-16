import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/enums.dart';
import '../../../services/storage/storage_service.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/dimensions.dart';
import '../../../utils/extensions/localization_extension.dart';
import '../../../utils/responsive.dart';

/// Recent mood entries as part of the insights dashboard: a horizontal strip
/// of emoji tiles with their weekday and date. Content block only.
class MoodHistoryCard extends StatelessWidget {
  const MoodHistoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moods = _recentMoods();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.smallSpacing),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Icon(
                Icons.mood,
                size: AppDimensions.iconSmall,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppDimensions.smallSpacing),
            Expanded(
              child: Text(
                context.tr('recentMoods'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (moods.isNotEmpty) ...[
              const SizedBox(width: AppDimensions.smallSpacing),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.smallSpacing,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Text(
                  '${moods.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppDimensions.elementSpacing),
        if (moods.isEmpty)
          Row(
            children: [
              Icon(
                Icons.mood_outlined,
                size: AppDimensions.iconMedium,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: AppDimensions.elementSpacing),
              Expanded(
                child: Text(
                  context.tr('noMoodsYet'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          )
        else
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: moods.length,
                separatorBuilder: (_, index) =>
                    const SizedBox(width: AppDimensions.elementSpacing),
                itemBuilder: (context, index) {
                  final entry = moods[index];
                  // "Mon, Sep 30" needs more room than the remaining width of
                  // a narrow screen can spare, so compact screens use the short
                  // form and a tighter tile.
                  final isCompact = context.isCompactScreen;
                  final tileWidth = context.scaleLength(76, min: 0.82);
                  final badge = context.scaleLength(44, min: 0.82);
                  return SizedBox(
                    width: tileWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: badge,
                          height: badge,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSmall,
                            ),
                            border: Border.all(
                              color:
                                  AppColors.secondary.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Icon(
                            entry.mood.icon,
                            size: 22,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.tinySpacing + 1),
                        Text(
                          DateFormat(isCompact ? 'MMM d' : 'EEE, MMM d')
                              .format(entry.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  List<({Mood mood, DateTime date})> _recentMoods() {
    final entries = StorageService()
        .getAllDailyData()
        .where((d) => d.mood != null && d.mood!.isNotEmpty)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return entries
        .take(6)
        .map(
          (d) => (mood: Mood.fromEmoji(d.mood!), date: d.date),
        )
        .toList();
  }
}
