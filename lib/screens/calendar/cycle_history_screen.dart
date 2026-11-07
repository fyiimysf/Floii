import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../services/cycle/cycle_calculation_service.dart';
import '../../services/storage/storage_service.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/date_extensions.dart';
import '../../utils/extensions/localization_extension.dart';
import '../../widgets/common/cards.dart';
import '../../widgets/common/indicators.dart';

/// Dedicated page listing every recorded cycle, newest first. It lives behind
/// its own route — reached from the calendar header — rather than trailing the
/// year grid, so a long history never buries the calendar itself.
class CycleHistoryScreen extends StatelessWidget {
  final Map<String, dynamic>? stats;

  const CycleHistoryScreen({super.key, this.stats});

  /// Uses the stats handed in by the caller; when the page is opened without
  /// them (e.g. from the pushed calendar route) it recomputes from storage.
  Map<String, dynamic> _resolveStats() {
    final provided = stats;
    if (provided != null) return provided;
    final storage = StorageService();
    return CycleCalculationService.calculateStats(
      storage.getAllDailyData(),
      defaultCycleLength: storage.getCycleLength(),
      defaultPeriodLength: storage.getMenstrualDays(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final periods =
        (_resolveStats()['periods'] as List<List<DateTime>>? ?? const [])
            .reversed
            .toList();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor:
                Theme.of(context).colorScheme.surface.withAlpha(180),
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: FlexibleSpaceBar(
                  title: Text(context.tr('cycleHistory')),
                  centerTitle: true,
                ),
              ),
            ),
          ),
          if (periods.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmpty(context),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPadding,
                  AppDimensions.elementSpacing,
                  AppDimensions.screenPadding,
                  AppDimensions.smallSpacing,
                ),
                child: Text(
                  context.tr('cycleHistoryCaption'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPadding),
              sliver: SliverList.builder(
                itemCount: periods.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(
                      bottom: AppDimensions.smallSpacing),
                  child: _CycleTile(period: periods[index]),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.sectionSpacing * 2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.elementSpacing),
              decoration: BoxDecoration(
                color: AppColors.period.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedClock05,
                color: AppColors.period,
                size: AppDimensions.iconLarge,
              ),
            ),
            const SizedBox(height: AppDimensions.elementSpacing),
            Text(
              context.tr('cycleHistoryCaption'),
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

/// Row for one recorded period: its date range and a duration chip, marked as
/// ongoing when today falls inside it.
class _CycleTile extends StatelessWidget {
  final List<DateTime> period;

  const _CycleTile({required this.period});

  static const _months = [
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
    'Dec',
  ];

  String _fmt(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = period.first;
    final end = period.last;
    final isOngoing = DateTime.now().isBetween(start, end);

    return ClayCard(
      entranceStep: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.elementSpacing,
        vertical: AppDimensions.elementSpacing,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.smallSpacing),
            decoration: BoxDecoration(
              color: AppColors.period.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedDroplet,
              color: AppColors.period,
              size: AppDimensions.iconMedium,
            ),
          ),
          const SizedBox(width: AppDimensions.elementSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_fmt(start)}  -  ${_fmt(end)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.tinySpacing),
                Text(
                  isOngoing
                      ? context.tr('current')
                      : '${context.tr('periodLength')}: ${period.length} ${context.tr('days')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isOngoing
                        ? AppColors.period
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isOngoing ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          PhaseChip(
            label: '${period.length}d',
            color: isOngoing ? AppColors.period : AppColors.fertile,
            isActive: isOngoing,
          ),
        ],
      ),
    );
  }
}
