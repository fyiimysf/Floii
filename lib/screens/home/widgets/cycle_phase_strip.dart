import 'package:floi/utils/extensions/localization_extension.dart';
import 'package:flutter/material.dart';
import '../../../models/cycle_models.dart';
import '../../../services/cycle/phase_service.dart';
import '../../../utils/constants/dimensions.dart';

class CyclePhaseStrip extends StatefulWidget {
  final Map<String, dynamic> stats;

  const CyclePhaseStrip({
    super.key,
    required this.stats,
  });

  @override
  State<CyclePhaseStrip> createState() => _CyclePhaseStripState();
}

class _CyclePhaseStripState extends State<CyclePhaseStrip> {
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cycle = PhaseService.currentCycleFromStats(widget.stats);
    if (cycle == null) return const SizedBox.shrink();

    final phases = PhaseService.calculatePhaseDetails(cycle, widget.stats);
    if (phases.isEmpty) return const SizedBox.shrink();

    final current = PhaseService.getCurrentPhase(phases) ?? phases.last;
    final color = PhaseService.getPhaseColor(current.name);
    final average = widget.stats['average'] as int? ?? 28;

    final now = DateTime.now();
    final cycleStart = DateTime(
        cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);
    final progress =
        (now.difference(cycleStart).inDays / average).clamp(0.0, 1.0);
    final daysLeft = PhaseService.daysRemainingInPhase(current) ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.smallSpacing,
        vertical: AppDimensions.smallSpacing,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: GestureDetector(
        onTap: _toggleExpanded,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhaseService.getPhaseIcon(current.name),
                      color: color,
                      size: AppDimensions.iconSmall - 2,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.smallSpacing),
                  Flexible(
                    child: Text(
                      current.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.elementSpacing),
                  Text(
                    '$daysLeft ${context.tr('days')} ${context.tr('left')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.smallSpacing),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: AppDimensions.durationNormal,
                    curve: AppDimensions.curveSmooth,
                    child: Icon(
                      Icons.expand_more,
                      size: AppDimensions.iconSmall + 2,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.tinySpacing + 2),
            _PhaseBar(
              phases: phases,
              current: current,
              progress: progress,
            ),
            const SizedBox(height: AppDimensions.tinySpacing + 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < phases.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        left: i == 0 ? 0 : AppDimensions.elementSpacing,
                      ),
                      child: _PhaseLabel(
                        phase: phases[i],
                        isCurrent: phases[i].name == current.name,
                      ),
                    ),
                ],
              ),
            ),
            ClipRect(
              child: AnimatedSize(
                duration: AppDimensions.durationNormal,
                curve: AppDimensions.curveSmooth,
                alignment: Alignment.topCenter,
                child: _expanded
                    ? _buildDetails(phases, current, theme)
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(
    List<PhaseDetail> phases,
    PhaseDetail current,
    ThemeData theme,
  ) {
    final color = PhaseService.getPhaseColor(current.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppDimensions.tinySpacing + 2),
        for (var i = 0; i < phases.length; i++) ...[
          _PhaseDetailRow(
            phase: phases[i],
            isCurrent: phases[i].name == current.name,
          ),
          if (i != phases.length - 1)
            const SizedBox(height: AppDimensions.tinySpacing),
        ],
        const SizedBox(height: AppDimensions.smallSpacing),
        Container(
          padding: const EdgeInsets.all(AppDimensions.smallSpacing),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
            ),
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
                  PhaseService.getPhaseDescription(current.name, context),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhaseDetailRow extends StatelessWidget {
  final PhaseDetail phase;
  final bool isCurrent;

  const _PhaseDetailRow({
    required this.phase,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = PhaseService.getPhaseColor(phase.name);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isCurrent ? 0.2 : 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            PhaseService.getPhaseIcon(phase.name),
            color: color,
            size: AppDimensions.iconSmall - 2,
          ),
        ),
        const SizedBox(width: AppDimensions.smallSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                phase.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isCurrent
                      ? color
                      : theme.colorScheme.onSurface.withValues(alpha: 0.9),
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '${_formatDate(phase.startDate)} - ${_formatDate(phase.endDate)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.smallSpacing),
        Text(
          isCurrent
              ? '${PhaseService.daysRemainingInPhase(phase) ?? 0} ${context.tr('days')} ${context.tr('left')}'
              : '${phase.duration} ${context.tr('days')}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isCurrent
                ? color
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
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
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _PhaseBar extends StatelessWidget {
  final List<PhaseDetail> phases;
  final PhaseDetail current;
  final double progress;

  const _PhaseBar({
    required this.phases,
    required this.current,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = PhaseService.getPhaseColor(current.name);
    final segments = phases.where((phase) => phase.duration > 0).toList();
    final clock = AppDimensions.durationSlow;
    final surface = theme.colorScheme.surface;
    final track = ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusCircular),
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++)
            Expanded(
              flex: segments[i].duration,
              child: Padding(
                padding: EdgeInsets.only(
                  right: i == segments.length - 1 ? 0 : 1,
                ),
                child: Container(
                  color: PhaseService.getPhaseColor(segments[i].name)
                      .withValues(alpha: 0.16),
                ),
              ),
            ),
        ],
      ),
    );
    final fill = ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusCircular),
      child: AnimatedFractionallySizedBox(
        duration: clock,
        curve: Curves.easeOutCubic,
        widthFactor: progress,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.6),
                color.withValues(alpha: 0.22),
              ],
            ),
          ),
        ),
      ),
    );

    return SizedBox(
      height: 10,
      child: Stack(
        children: [
          Positioned.fill(child: track),
          Positioned.fill(child: fill),
          if (progress > 0)
            Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: progress,
                alignment: Alignment.centerRight,
                child: AnimatedContainer(
                  duration: clock,
                  curve: Curves.easeOutCubic,
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhaseLabel extends StatelessWidget {
  final PhaseDetail phase;
  final bool isCurrent;

  const _PhaseLabel({
    required this.phase,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = PhaseService.getPhaseColor(phase.name);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isCurrent ? color : color.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          phase.name,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isCurrent
                ? color
                : theme.colorScheme.onSurface.withOpacity(0.5),
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
