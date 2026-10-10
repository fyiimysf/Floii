// lib/screens/trends/widgets/regularity_card.dart

import 'package:floi/utils/extensions/localization_extension.dart';
import 'package:flutter/material.dart' hide ProgressIndicator;
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/dimensions.dart';
import '../../../widgets/common/indicators.dart';
import '../../../widgets/common/sparkline.dart';

/// A headline regularity score with a status description and a small
/// consistency sparkline.
class RegularityCard extends StatelessWidget {
  final int consistency;
  final List<double> cycleSeries;

  const RegularityCard({
    super.key,
    required this.consistency,
    required this.cycleSeries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = consistency >= 85
        ? AppColors.success
        : consistency >= 60
            ? AppColors.ovulation
            : AppColors.period;
    final status = consistency >= 85
        ? context.tr('regularityHigh')
        : consistency >= 60
            ? context.tr('regularityModerate')
            : context.tr('regularityLow');

    return Row(
      children: [
        ProgressIndicator(
          value: consistency / 100,
          size: 84,
          strokeWidth: 9,
          color: color,
          label: context.tr('regular'),
        ),
        const SizedBox(width: AppDimensions.elementSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('cycleConsistency'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppDimensions.tinySpacing),
              Text(
                '$consistency% • $status',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppDimensions.smallSpacing),
              Sparkline(
                values: cycleSeries,
                color: color,
                height: 36,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
