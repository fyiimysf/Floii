import 'package:hugeicons/hugeicons.dart';
// lib/screens/trends/trends_screen.dart

import 'package:flutter/material.dart';
import '../../services/cycle/cycle_analytics_service.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/localization_extension.dart';
import '../../widgets/common/cards.dart';
import '../../widgets/common/page_header.dart';
import '../../widgets/common/section_header.dart';
import 'widgets/cycle_length_chart.dart';
import 'widgets/distribution_card.dart';
import 'widgets/regularity_card.dart';

/// Rich cycle trend & pattern analysis: regularity score, cycle-length
/// drift over time, and the distribution of observed cycle lengths.
class TrendsScreen extends StatelessWidget {
  final Map<String, dynamic> stats;

  const TrendsScreen({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final periods = stats['periods'] as List<List<DateTime>>? ?? [];
    final analytics =
        CycleAnalyticsService.computeAnalyticsFromPeriods(periods);
    final trends = CycleAnalyticsService.buildTrendsFromPeriods(periods);

    final cycleLengths =
        (analytics['cycleLengths'] as List<dynamic>? ?? []).cast<int>();
    final consistency = analytics['consistency'] as int? ?? 0;
    final lastCycleValue = cycleLengths.isNotEmpty
        ? cycleLengths.last.toDouble()
        : (analytics['averageCycle'] as double? ?? 28.0);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
icon: Icons.show_chart,
              title: context.tr('trends'),
              color: AppColors.secondary,
            ),
          ),
          if (cycleLengths.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmpty(context),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  RegularityCard(
                    consistency: consistency,
                    cycleSeries:
                        cycleLengths.map((e) => e.toDouble()).toList(),
                  ),
                  const SizedBox(height: AppDimensions.elementSpacing),
                  CycleLengthChart(
                    trends: trends,
                    averageCycle: analytics['averageCycle'] as double?,
                  ),
                  const SizedBox(height: AppDimensions.elementSpacing),
                  DistributionCard(cycleLengths: cycleLengths),
                  const SizedBox(height: AppDimensions.elementSpacing),
                  _buildFindings(context,
                      consistency: consistency,
                      lastCycle: lastCycleValue,
                      averageCycle:
                          analytics['averageCycle'] as double?),
                  const SizedBox(height: AppDimensions.sectionSpacing),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFindings(BuildContext context, {
    required int consistency,
    required double lastCycle,
    required double? averageCycle,
  }) {
    final theme = Theme.of(context);
    final avg = averageCycle ?? lastCycle;
    final drift = lastCycle - avg;
    final color = drift.abs() <= 3
        ? AppColors.success
        : drift.abs() <= 6
            ? AppColors.ovulation
            : AppColors.period;

    final headline = drift.abs() <= 3
        ? context.tr('findingStable')
        : drift > 0
            ? context.tr('findingLonger')
            : context.tr('findingShorter');

    final detail = context.trArgs('findingDetail', {
      'lastCycle': lastCycle.round().toString(),
      'average': avg.round().toString(),
    });

    return ClayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: context.tr('patternFindings'),
            icon: HugeIcons.strokeRoundedBulb,
            caption: context.tr('patternFindingsCaption'),
          ),
          const SizedBox(height: AppDimensions.elementSpacing),
          Container(
            padding: const EdgeInsets.all(AppDimensions.elementSpacing),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedSun03,
                  color: color,
                  size: AppDimensions.iconLarge,
                ),
                const SizedBox(width: AppDimensions.elementSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.tinySpacing),
                      Text(
                        detail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
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

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: HugeIcons.strokeRoundedChartLineData01,
              size: AppDimensions.iconXL * 2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppDimensions.elementSpacing),
            Text(
              context.tr('trendsNeedData'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimensions.smallSpacing),
            Text(
              context.tr('trackPeriodHint'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}