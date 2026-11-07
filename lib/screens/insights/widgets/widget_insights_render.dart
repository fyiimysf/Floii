import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/cycle_models.dart';
import '../../../services/cycle/cycle_calculation_service.dart';
import '../../../services/cycle/phase_service.dart';
import '../../../services/localization/app_localizations.dart';
import '../../../utils/constants/colors.dart';

/// Fixed logical size the Insights overview widget face is rendered at. The
/// height is tuned to the content so the face has no slack below the hint.
const Size kInsightsWidgetLogicalSize = Size(360, 284);

/// Builds the off-screen rendered face of the "Insights overview" home-screen
/// widget: the hero `CycleNowCard` from the Insights tab (phase, progress ring,
/// next period / ovulation milestones, phase track and hint) redrawn
/// self-contained because it is painted by `HomeWidget.renderFlutterWidget`
/// outside the normal widget tree.
Widget buildInsightsWidgetFace({
  required AppLocalizations loc,
  required bool isDark,
  required DateTime today,
  required Map<String, dynamic> stats,
}) {
  final periods = stats['periods'] as List<List<DateTime>>? ?? [];
  final hasData = periods.isNotEmpty;
  final average = stats['average'] as int? ?? 28;

  final surface = isDark ? AppColors.cardDark : AppColors.cardLight;
  final textPrimary = isDark ? Colors.white : AppColors.textPrimary;
  final textMuted = isDark ? Colors.white70 : AppColors.textMuted;

  final cycle = CycleCalculationService.getCurrentCycle(periods);
  final cycleStart = cycle?.startDate;
  final phases = cycle == null
      ? const <PhaseDetail>[]
      : PhaseService.calculatePhaseDetails(cycle, stats);

  final cycleDay = cycleStart != null
      ? today.difference(cycleStart).inDays + 1
      : CycleCalculationService.getCurrentCycleDay(
          periods,
          averageCycleLength: average,
        );

  final phaseName =
      hasData ? PhaseService.getPhaseName(today, stats) : null;
  final phaseColor = phaseName == null
      ? AppColors.primary
      : PhaseService.getPhaseColor(phaseName);
  final phaseHint = phaseName == null
      ? loc.translate('trackPeriodHint')
      : loc.translate('${phaseName.toLowerCase()}Hint');

  final totalDays = phases.isNotEmpty
      ? phases.last.endDate.difference(cycleStart!).inDays + 1
      : average;

  return SizedBox(
    width: kInsightsWidgetLogicalSize.width,
    height: kInsightsWidgetLogicalSize.height,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        color: surface,
        // The face is painted off-screen by HomeWidget.renderFlutterWidget,
        // which provides no Theme, so Material would otherwise fall back to
        // the platform font. Seed the default text style with Nunito so every
        // inline TextStyle that omits a family inherits it.
        textStyle: const TextStyle(fontFamily: 'Nunito'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: hasData
              ? _Content(
                  loc: loc,
                  today: today,
                  stats: stats,
                  cycleStart: cycleStart!,
                  cycleDay: cycleDay,
                  phaseName: phaseName!,
                  phaseColor: phaseColor,
                  phaseHint: phaseHint,
                  phases: phases,
                  totalDays: totalDays,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                )
              : _EmptyState(
                  loc: loc,
                  textMuted: textMuted,
                  surface: surface,
                ),
        ),
      ),
    ),
  );
}

class _Content extends StatelessWidget {
  final AppLocalizations loc;
  final DateTime today;
  final Map<String, dynamic> stats;
  final DateTime cycleStart;
  final int? cycleDay;
  final String phaseName;
  final Color phaseColor;
  final String phaseHint;
  final List<PhaseDetail> phases;
  final int totalDays;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;

  const _Content({
    required this.loc,
    required this.today,
    required this.stats,
    required this.cycleStart,
    required this.cycleDay,
    required this.phaseName,
    required this.phaseColor,
    required this.phaseHint,
    required this.phases,
    required this.totalDays,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
  });

  double get _progress => cycleDay == null
      ? 0.0
      : ((cycleDay! - 1) / totalDays).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final prediction = stats['prediction'] as DateTime?;
    final ovulation = stats['ovulationDate'] as DateTime?;

    final daysUntil = prediction != null
        ? _dayDiff(prediction, today)
        : null;
    final daysToOvulation =
        ovulation != null ? _dayDiff(ovulation, today) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      phaseColor.withValues(alpha: 0.24),
                      phaseColor.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  PhaseService.getPhaseIcon(phaseName),
                  color: phaseColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('currentPhase').toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: phaseColor.withValues(alpha: 0.8),
                        fontSize: 11,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phaseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: phaseColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: phaseColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  cycleDay != null ? '${loc.translate('Day')} $cycleDay' : '—',
                  maxLines: 1,
                  style: TextStyle(
                    color: phaseColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProgressRing(
                progress: _progress,
                color: phaseColor,
                day: cycleDay ?? 1,
                total: totalDays,
                loc: loc,
                trackColor: textMuted.withValues(alpha: 0.14),
                textMuted: textMuted,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Milestone(
                      icon: Icons.event_outlined,
                      label: loc.translate('nextPeriod'),
                      value: daysUntil == null
                          ? '—'
                          : daysUntil <= 0
                              ? loc.translate('today')
                              : '$daysUntil ${loc.translate('days')}',
                      detail: prediction != null
                          ? DateFormat('d MMM').format(prediction)
                          : null,
                      color: AppColors.primary,
                      isDark: isDark,
                      textPrimary: textPrimary,
                    ),
                    _Milestone(
                      icon: Icons.wb_sunny_outlined,
                      label: loc.translate('ovulationPhase'),
                      value: daysToOvulation == null
                          ? '—'
                          : daysToOvulation <= 0
                              ? loc.translate('today')
                              : '$daysToOvulation ${loc.translate('days')}',
                      detail: ovulation != null
                          ? DateFormat('d MMM').format(ovulation)
                          : null,
                      color: AppColors.ovulation,
                      isDark: isDark,
                      textPrimary: textPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (phases.isNotEmpty)
          _PhaseTrack(phases: phases, progress: _progress, phaseColor: phaseColor)
        else
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: textMuted.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          height: 16,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              cycleDay != null
                  ? '${loc.translate('Day')} $cycleDay ${loc.translate('of')} '
                      '$totalDays · ${DateFormat('MMM d').format(cycleStart)}'
                  : DateFormat('MMM d').format(cycleStart),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 32,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  size: 14,
                  color: phaseColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  phaseHint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textMuted.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _dayDiff(DateTime a, DateTime b) => DateTime(a.year, a.month, a.day)
      .difference(DateTime(b.year, b.month, b.day))
      .inDays;
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  final Color color;
  final int day;
  final int total;
  final AppLocalizations loc;
  final Color trackColor;
  final Color textMuted;

  const _ProgressRing({
    required this.progress,
    required this.color,
    required this.day,
    required this.total,
    required this.loc,
    required this.trackColor,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    const diameter = 88.0;
    const stroke = 8.0;
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(diameter, diameter),
            painter: _RingPainter(
              progress: progress,
              color: color,
              strokeWidth: stroke,
              trackColor: trackColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 1),
              Text(
                loc.translateWithArgs('dayOfCycle', {'total': total}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - strokeWidth / 2 - 4;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = trackColor,
    );

    if (progress > 0.003) {
      final sweep = 2 * math.pi * progress;
      const start = -math.pi / 2;
      final rect = Rect.fromCircle(center: center, radius: radius);

      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.sweep(
            center,
            [color.withValues(alpha: 0.45), color],
          ),
      );

      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.trackColor != trackColor;
}

class _Milestone extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final Color color;
  final bool isDark;
  final Color textPrimary;

  const _Milestone({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.textPrimary,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.surfaceLight.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(width: 5),
                      Text(
                        detail!,
                        maxLines: 1,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseTrack extends StatelessWidget {
  final List<PhaseDetail> phases;
  final double progress;
  final Color phaseColor;

  const _PhaseTrack({
    required this.phases,
    required this.progress,
    required this.phaseColor,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: SizedBox(
        height: 16,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Row(
              children: [
                for (final phase in phases)
                  Expanded(
                    flex: phase.duration < 1 ? 1 : phase.duration,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: PhaseService.getPhaseColor(phase.name)
                              .withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Align(
              alignment: Alignment(-1 + 2 * progress, 0),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: phaseColor, width: 2.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations loc;
  final Color textMuted;
  final Color surface;

  const _EmptyState({
    required this.loc,
    required this.textMuted,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.calendar_today,
            color: AppColors.primary,
            size: 40,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          loc.translate('welcomeTitle'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          loc.translate('trackPeriodHint'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textMuted,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
