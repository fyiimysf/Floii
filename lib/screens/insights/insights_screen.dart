import 'dart:ui';

import 'package:flutter/material.dart';
import '../../models/cycle_models.dart';
import '../../services/cycle/cycle_calculation_service.dart';
import '../../services/cycle/phase_service.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/localization_extension.dart';
import '../../widgets/common/dashboard_surface.dart';
import 'widgets/cycle_now_card.dart';
import 'widgets/fertility_forecast.dart';
import 'widgets/mood_history_card.dart';
import 'widgets/phase_breakdown.dart';
import 'widgets/statistics_grid.dart';
import 'widgets/week_forecast_card.dart';

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

  PredictedRange? _currentCycle(Map<String, dynamic> stats) {
    final currentCycle =
        CycleCalculationService.getCurrentCycle(stats['periods'] ?? []);
    if (currentCycle == null) return null;

    final averageCycle = stats['average'] as int? ?? 28;
    final now = DateTime.now();
    final daysSinceLastPeriod = now.difference(currentCycle.startDate).inDays;

    if (daysSinceLastPeriod >= averageCycle) {
      final cyclesPassed = daysSinceLastPeriod ~/ averageCycle;
      final predictedCycleStart = currentCycle.startDate.add(
        Duration(days: cyclesPassed * averageCycle),
      );
      return PredictedRange(
        index: cyclesPassed - 1,
        startDate: predictedCycleStart,
        endDate: predictedCycleStart.add(
          Duration(days: (stats['currentPeriodLength'] as int? ?? 5) - 1),
        ),
      );
    }

    return currentCycle;
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
    final periods = stats['periods'] as List<List<DateTime>>? ?? [];

    final cycle = _currentCycle(stats);
    final phases = cycle == null
        ? const <PhaseDetail>[]
        : PhaseService.calculatePhaseDetails(cycle, stats);
    final cycleStart = cycle?.startDate;

    final currentCycleDay = cycleStart != null
        ? DateTime.now().difference(cycleStart).inDays + 1
        : CycleCalculationService.getCurrentCycleDay(
            periods,
            averageCycleLength: stats['average'] ?? 28,
          );

    final currentPhase =
        cycle != null ? PhaseService.getCurrentPhase(phases) : null;
    final phaseName =
        currentPhase?.name ?? PhaseService.getPhaseName(DateTime.now(), stats);
    final phaseColor = PhaseService.getPhaseColor(phaseName);
    final currentPhaseDisplay = currentPhase != null
        ? _phaseDisplayName(currentPhase.name, context)
        : PhaseService.getPhaseDisplay(DateTime.now(), stats, context);
    final phaseHint = context.tr('${phaseName.toLowerCase()}Hint');

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // FloatingTabBar(
          //   title: context.tr('insights'),
          //   accentColor: AppColors.ovulation,
          //   onAction: _openTrends,
          //   actionLabel: context.tr('trends'),
          //   actionTooltip: context.tr('viewTrends'),
          // ),

          SliverAppBar(
            // 1. Keeps the bar stuck to the top when scrolling
            pinned: true,
            expandedHeight: 70.0,
            backgroundColor:
                Theme.of(context).colorScheme.surface.withAlpha(180),
            elevation: 0,
            scrolledUnderElevation: 0,
            // backgroundColor: AppColors.cardDark.withAlpha(200),
            actions: [
              IconButton(
                onPressed: _openTrends,
                icon: Icon(
                  Icons.show_chart_rounded,
                  color: AppColors.ovulation,
                  size: 26,
                ),
              ),
              // IconButton(onPressed: _openYearPicker, icon: HugeIcon(icon:  HugeIcons.strokeRoundedCalendar03, color: AppColors.primary, size: 26,)),
              // TextButton(
              //     onPressed: _openTrends,
              //     child: Text(
              //       'Trends',
              //       style: TextStyle(color: AppColors.ovulation, fontSize: 16, fontWeight: FontWeight.w600),
              //     ))
            ],
            // 2. Optional: Adjusts how content collapses under the status bar
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: FlexibleSpaceBar(
                    // centerTitle: true,
                    title: Text(
                      context.tr('insights'),
                    ),
                    centerTitle: true,
                  )),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppDimensions.smallSpacing),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.borderMedium),
            sliver: SliverToBoxAdapter(
              child: DashboardSurface(
                children: [
                  CycleNowCard(
                    stats: stats,
                    phases: phases,
                    cycleStart: cycleStart ?? DateTime.now(),
                    currentPhase: currentPhaseDisplay,
                    phaseHint: phaseHint,
                    phaseColor: phaseColor,
                    cycleDay: currentCycleDay,
                    prediction: prediction,
                  ),
                  const DashboardSectionDivider(),
                  dashboardSectionBlock(
                      context, WeekForecastCard(stats: stats)),
                  const DashboardSectionDivider(),
                  dashboardSectionBlock(context, StatisticsGrid(stats: stats)),
                  const DashboardSectionDivider(),
                  dashboardSectionBlock(context, PhaseBreakdown(stats: stats)),
                  const DashboardSectionDivider(),
                  dashboardSectionBlock(context, MoodHistoryCard()),
                  if (prediction != null) ...[
                    const DashboardSectionDivider(),
                    dashboardSectionBlock(
                      context,
                      FertilityForecast(prediction: prediction),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Breathing room below the surface so the last section never sits
          // flush against the bottom edge of the page.
          SliverToBoxAdapter(
            child: SizedBox(
              height: AppDimensions.elementSpacing * 2,
            ),
          ),
        ],
      ),
    );
  }

  String _phaseDisplayName(String name, BuildContext context) {
    switch (name) {
      case 'Menstrual':
        return context.tr('menstrualPhase');
      case 'Follicular':
        return context.tr('follicularPhase');
      case 'Ovulation':
        return context.tr('ovulationPhase');
      case 'Luteal':
        return context.tr('lutealPhase');
      default:
        return name;
    }
  }
}
