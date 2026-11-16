import 'package:hugeicons/hugeicons.dart';
// lib/screens/trends/widgets/distribution_card.dart

import 'package:floi/utils/extensions/localization_extension.dart';
import 'package:flutter/material.dart';
import '../../../services/cycle/cycle_analytics_service.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/dimensions.dart';
import '../../../widgets/common/h_bar_chart.dart';

/// Shows how often each cycle length occurs as horizontal ranking bars.
class DistributionCard extends StatelessWidget {
  final List<int> cycleLengths;

  const DistributionCard({
    super.key,
    required this.cycleLengths,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dist = CycleAnalyticsService.cycleDistribution(cycleLengths);

    final items = dist.map((d) => (
          label: '${d.length} ${context.tr('days')}',
          value: d.count.toDouble(),
          color: theme.colorScheme.primary,
        ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                padding: const EdgeInsets.all(AppDimensions.elementSpacing),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedChartBarLine,
                  color: AppColors.secondary,
                  size: AppDimensions.iconMedium,
                )),
            const SizedBox(width: AppDimensions.elementSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('cycleDistribution'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    context.tr('cycleDistributionCaption'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.elementSpacing),
        if (items.isEmpty)
          Text(
            context.tr('noCycleData'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          HBarChart(items: items.toList(), height: 14),
      ],
    );
  }
}
