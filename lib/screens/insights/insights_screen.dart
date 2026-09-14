import 'package:flutter/material.dart' hide ProgressIndicator;
import '../../services/cycle/cycle_calculation_service.dart';
import '../../services/cycle/phase_service.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/localization_extension.dart';
import '../../widgets/common/cards.dart';
import '../../widgets/common/floating_tab_bar.dart';
import '../../widgets/common/indicators.dart';
import 'widgets/fertility_forecast.dart';
import 'widgets/phase_breakdown.dart';
import 'widgets/statistics_grid.dart';

class InsightsScreen extends StatefulWidget {
  final Map<String, dynamic> stats;

  const InsightsScreen({super.key, required this.stats});

  @override
  State<InsightsScreen> createState() => InsightsScreenState();
}

class InsightsScreenState extends State<InsightsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  DateTime? _getCurrentPrediction(Map<String, dynamic> stats) {
    final originalPrediction = stats['prediction'] as DateTime?;
    if (originalPrediction == null) return null;

    final periods = stats['periods'] as List<List<DateTime>>? ?? [];
    if (periods.isEmpty) return originalPrediction;

    final lastPeriodStart = periods.last.first;
    final averageCycle = stats['average'] as int? ?? 28;
    final now = DateTime.now();

    final daysSinceLastPeriod = now.difference(lastPeriodStart).inDays;

    if (daysSinceLastPeriod <= averageCycle) {
      return originalPrediction;
    }

    final cyclesPassed = (daysSinceLastPeriod / averageCycle).ceil();
    return lastPeriodStart.add(Duration(days: cyclesPassed * averageCycle));
  }

  void _openTrends() {
    Navigator.of(context).pushNamed('/trends', arguments: widget.stats);
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final prediction = _getCurrentPrediction(stats);
    final phaseName = PhaseService.getPhaseName(DateTime.now(), stats);
    final phaseColor = PhaseService.getPhaseColor(phaseName);
    final currentPhase =
        PhaseService.getPhaseDisplay(DateTime.now(), stats, context);
    final cycleProgress = CycleCalculationService.calculateProgress(
      stats['periods'] ?? [],
      stats['average'] ?? 28,
    );
    final currentCycleDay = CycleCalculationService.getCurrentCycleDay(
      stats['periods'] ?? [],
      averageCycleLength: stats['average'] ?? 28,
    );
    final daysUntil = prediction?.difference(DateTime.now()).inDays;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          FloatingTabBar(
            title: context.tr('insights'),
            accentColor: AppColors.ovulation,
            onAction: _openTrends,
            actionLabel: context.tr('trends'),
            actionTooltip: context.tr('viewTrends'),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppDimensions.smallSpacing),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProgressCard(cycleProgress, currentPhase, phaseColor,
                    stats, context, currentCycleDay, daysUntil),
                const SizedBox(height: AppDimensions.smallSpacing),
                StatisticsGrid(stats: stats),
                const SizedBox(height: AppDimensions.smallSpacing),
                PhaseBreakdown(stats: stats),
                const SizedBox(height: AppDimensions.sectionSpacing),
                if (prediction != null)
                  FertilityForecast(prediction: prediction),
                const SizedBox(height: AppDimensions.sectionSpacing),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
      double progress,
      String currentPhase,
      Color phaseColor,
      Map<String, dynamic> stats,
      BuildContext context,
      int? currentCycleDay,
      int? daysUntil) {
    return ClayCard(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 300;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!isNarrow) ...[
                    ProgressIndicator(
                      value: progress,
                      size: 92,
                      strokeWidth: 12,
                      color: phaseColor,
                      showPercentage: true,
                    ),
                    const SizedBox(width: AppDimensions.elementSpacing),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: isNarrow
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: AppDimensions.smallSpacing),
                        Text(
                          currentPhase,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: phaseColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDimensions.tinySpacing),
                        Text(
                          currentCycleDay != null
                              ? '${context.tr('Day')} $currentCycleDay ${context.tr('of')} ${stats['average'] ?? 28}'
                              : 'Track your period to see cycle day',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (daysUntil != null && daysUntil >= 0) ...[
                          const SizedBox(height: AppDimensions.tinySpacing),
                          Text(
                            '$daysUntil ${context.tr('days')} ${context.tr('In')} ${context.tr('nextPeriod')}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.elementSpacing),
              Stack(
                alignment: AlignmentGeometry.centerRight,
                children: [
                  if (isNarrow) ...[
                    LinearProgressIndicator(
                      value: progress,
                      year2023: false,
                      color: phaseColor,
                      minHeight: 30,
                      borderRadius: BorderRadiusDirectional.circular(4),
                      backgroundColor: phaseColor.withAlpha(60),
                      stopIndicatorColor: phaseColor.withAlpha(255),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}