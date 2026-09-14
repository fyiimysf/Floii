import 'package:floi/utils/extensions/localization_extension.dart';
import 'package:flutter/material.dart';
import '../../../models/cycle_models.dart';
import '../../../services/cycle/cycle_calculation_service.dart';
import '../../../services/cycle/phase_service.dart';
import '../../../utils/constants/dimensions.dart';
import '../../../widgets/common/phase_widgets.dart';

class PhaseBreakdown extends StatelessWidget {
  final Map<String, dynamic> stats;

  const PhaseBreakdown({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final currentCycle = CycleCalculationService.getCurrentCycle(
      stats['periods'] ?? [],
    );

    if (currentCycle == null) {
      return const SizedBox.shrink();
    }

    final averageCycle = stats['average'] as int? ?? 28;
    final now = DateTime.now();
    final daysSinceLastPeriod = now.difference(currentCycle.startDate).inDays;

    PredictedRange cycleToUse = currentCycle;

    if (daysSinceLastPeriod >= averageCycle) {
      final cyclesPassed = daysSinceLastPeriod ~/ averageCycle;
      final predictedCycleStart = currentCycle.startDate.add(
        Duration(days: cyclesPassed * averageCycle),
      );
      final predictedCycleEnd = predictedCycleStart.add(
        Duration(days: (stats['currentPeriodLength'] as int? ?? 5) - 1),
      );

      cycleToUse = PredictedRange(
        index: cyclesPassed - 1,
        startDate: predictedCycleStart,
        endDate: predictedCycleEnd,
      );
    }

    final phases = PhaseService.calculatePhaseDetails(cycleToUse, stats);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final currentPhase = PhaseService.getCurrentPhase(phases);
    final crossAxisCount = MediaQuery.sizeOf(context).width < 600 ? 2 : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('phaseBreakdown'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppDimensions.elementSpacing),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 146 * textScale,
            mainAxisSpacing: AppDimensions.elementSpacing,
            crossAxisSpacing: AppDimensions.elementSpacing,
          ),
          children: [
            for (final phase in phases)
              PhaseCard(
                phase: phase,
                isCurrent: identical(phase, currentPhase),
                isCompleted: currentPhase == null
                    ? false
                    : phase.endDate.isBefore(currentPhase.startDate),
              ),
          ],
        ),
      ],
    );
  }
}
