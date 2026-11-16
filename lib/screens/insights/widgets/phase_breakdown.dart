import 'package:floi/utils/extensions/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../models/cycle_models.dart';
import '../../../services/cycle/cycle_calculation_service.dart';
import '../../../services/cycle/phase_service.dart';
import '../../../utils/constants/dimensions.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/common/section_header.dart';

/// Phase map of the current cycle as part of the insights dashboard: four
/// spacious phase cells with their cycle-day ranges and a note about the phase
/// happening right now. Content block only — the surface provides the card.
class PhaseBreakdown extends StatelessWidget {
  final Map<String, dynamic> stats;

  const PhaseBreakdown({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phases = _phasesForToday();

    if (phases.isEmpty) {
      return Row(
        children: [
          Icon(
            Icons.info_outline,
            size: AppDimensions.iconMedium,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: AppDimensions.elementSpacing),
          Expanded(
            child: Text(
              context.tr('trackPeriodHint'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      );
    }

    final currentPhase = PhaseService.getCurrentPhase(phases);
    final cycleStart = phases.isNotEmpty
        ? phases.first.startDate
        : CycleCalculationService.getCurrentCycle(stats['periods'] ?? [])
            ?.startDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: context.tr('cyclePhases'),
          icon: HugeIcons.strokeRoundedBulb,
          caption: context.tr('trackYourJourney'),
        ),
        const SizedBox(height: AppDimensions.elementSpacing),
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Four phases read as one inline row when there is room; on a
              // narrow phone they drop into a 2x2 block so each name keeps its
              // full text.
              final columns = context.screenSize.isCompact ? 2 : 4;
              const gap = AppDimensions.smallSpacing;
              final cellWidth =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final phase in phases)
                    SizedBox(
                      width: cellWidth,
                      child: _PhaseCell(
                        name: phase.name,
                        startDay: cycleStart == null
                            ? null
                            : phase.startDate.difference(cycleStart).inDays + 1,
                        endDay: cycleStart == null
                            ? null
                            : phase.endDate.difference(cycleStart).inDays + 1,
                        isCurrent: identical(phase, currentPhase),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppDimensions.elementSpacing),
        if (currentPhase != null) _PhaseNote(phase: currentPhase),
      ],
    );
  }

  List<PhaseDetail> _phasesForToday() {
    final currentCycle = CycleCalculationService.getCurrentCycle(
      stats['periods'] ?? [],
    );
    if (currentCycle == null) return const [];

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

    return PhaseService.calculatePhaseDetails(cycleToUse, stats);
  }
}

class _PhaseCell extends StatelessWidget {
  final String name;
  final int? startDay;
  final int? endDay;
  final bool isCurrent;

  const _PhaseCell({
    required this.name,
    this.startDay,
    this.endDay,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = PhaseService.getPhaseColor(name);
    final localized = _localizedName(context, name);
    final isCompact = context.isCompactScreen;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.tinySpacing + 2,
        vertical: AppDimensions.elementSpacing,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        gradient: isCurrent
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.18),
                  color.withValues(alpha: 0.05),
                ],
              )
            : null,
        color: isCurrent
            ? null
            : theme.colorScheme.onSurface.withValues(alpha: 0.03),
        border: Border.all(
          color: isCurrent ? color.withValues(alpha: 0.55) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: isCurrent ? 0.22 : 0.14),
                ),
                child: Icon(
                  PhaseService.getPhaseIcon(name),
                  color: color,
                  size: AppDimensions.iconSmall + 2,
                ),
              ),
              if (isCurrent)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.smallSpacing + 2),
          // Long phase names wrap to a second line and, if a single word is
          // still too wide for the cell, scale down rather than get cut off.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              localized,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          if (startDay != null && endDay != null)
            // Compact cells drop the "Day" prefix to keep the range on one line.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isCompact
                    ? '$startDay–$endDay'
                    : '${context.tr('Day')} $startDay–$endDay',
                maxLines: 1,
                softWrap: false,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _localizedName(BuildContext context, String name) {
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

class _PhaseNote extends StatelessWidget {
  final PhaseDetail phase;

  const _PhaseNote({required this.phase});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = PhaseService.getPhaseColor(phase.name);
    final daysLeft = PhaseService.daysRemainingInPhase(phase) ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.elementSpacing),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: AppDimensions.iconSmall,
            color: color,
          ),
          const SizedBox(width: AppDimensions.smallSpacing),
          Expanded(
            child: Text(
              '${PhaseService.getPhaseDescription(phase.name, context)} '
              '· ${context.trArgs('daysLeft', {'days': '$daysLeft'})}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
