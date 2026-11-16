import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/cycle/cycle_calculation_service.dart';
import '../../../services/cycle/phase_service.dart';
import '../../../services/cycle/prediction_service.dart';
import '../../../services/localization/app_localizations.dart';
import '../../../models/enums.dart';
import '../../../utils/constants/colors.dart';

/// Fixed logical size the home-screen widget face is rendered at. Kept in one
/// place so the Dart render and the Android widget can agree on proportions.
const Size kHomeWidgetLogicalSize = Size(360, 432);

/// Builds the off-screen rendered face of the Floii home-screen widget.
///
/// This mirrors the visual language of the in-app home screen (the cycle status
/// card and the month grid of [CalendarWidget]) but is deliberately
/// self-contained: it takes no [BuildContext], no theme lookup and no
/// callbacks, because it is painted by `HomeWidget.renderFlutterWidget` outside
/// the normal widget tree. Colours, typography and the phase palette track
/// [AppColors] and [PhaseService] so the widget looks like the app.
Widget buildHomeWidgetFace({
  required AppLocalizations loc,
  required bool isDark,
  required DateTime today,
  required Map<String, dynamic> stats,
  required Set<String> periodKeys,
  required List<DateTime> predictedPeriods,
}) {
  final month = DateTime(today.year, today.month, 1);
  final periods = stats['periods'] as List<List<DateTime>>? ?? [];
  final hasData = periods.isNotEmpty;
  final average = stats['average'] as int? ?? 28;
  final prediction = stats['prediction'] as DateTime?;

  final cycleDay = hasData
      ? CycleCalculationService.getCurrentCycleDay(
          periods,
          averageCycleLength: average,
        )
      : null;
  final phase = hasData ? PhaseService.getPhase(today, stats) : null;
  final nextPeriod = _nextPeriodStart(stats, today);
  final fertile = prediction != null
      ? PredictionService.predictFertileWindow(prediction)
      : <DateTime>[];
  final ovulation = prediction != null
      ? PredictionService.predictOvulation(prediction)
      : null;

  final surface = isDark ? AppColors.cardDark : AppColors.cardLight;
  final textPrimary = isDark ? Colors.white : AppColors.textPrimary;
  final textMuted = isDark ? Colors.white70 : AppColors.textMuted;

  return SizedBox(
    width: kHomeWidgetLogicalSize.width,
    height: kHomeWidgetLogicalSize.height,
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'Floii',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMMM y').format(month),
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!hasData)
                _NoDataHint(loc: loc, textMuted: textMuted)
              else
                _StatsRow(
                  loc: loc,
                  isDark: isDark,
                  cycleDay: cycleDay,
                  totalDays: average,
                  phase: phase,
                  nextPeriod: nextPeriod,
                  today: today,
                  fertile: fertile,
                  ovulation: ovulation,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              const SizedBox(height: 14),
              _WeekdayHeader(textMuted: textMuted),
              const SizedBox(height: 6),
              Expanded(
                child: _MonthGrid(
                  month: month,
                  today: today,
                  stats: stats,
                  periodKeys: periodKeys,
                  predictedPeriods: predictedPeriods,
                  fertile: fertile,
                  ovulation: ovulation,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

DateTime? _nextPeriodStart(Map<String, dynamic> stats, DateTime today) {
  final prediction = stats['prediction'] as DateTime?;
  if (prediction == null) return null;

  final average = stats['average'] as int? ?? 28;
  final periodLength = (stats['averagePeriodLength'] as int?) ??
      (stats['currentPeriodLength'] as int?) ??
      5;
  final todayStart = DateTime(today.year, today.month, today.day);
  var start = DateTime(prediction.year, prediction.month, prediction.day);
  var guard = 0;
  while (start.add(Duration(days: periodLength - 1)).isBefore(todayStart) &&
      guard < 240) {
    start = start.add(Duration(days: average));
    guard++;
  }
  return start;
}

String _ordinal(int n) {
  final mod = n % 100;
  if (mod >= 11 && mod <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}

class _StatsRow extends StatelessWidget {
  final AppLocalizations loc;
  final bool isDark;
  final int? cycleDay;
  final int totalDays;
  final CyclePhase? phase;
  final DateTime? nextPeriod;
  final DateTime today;
  final List<DateTime> fertile;
  final DateTime? ovulation;
  final Color textPrimary;
  final Color textMuted;

  const _StatsRow({
    required this.loc,
    required this.isDark,
    required this.cycleDay,
    required this.totalDays,
    required this.phase,
    required this.nextPeriod,
    required this.today,
    required this.fertile,
    required this.ovulation,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final phaseAccent = phase == null
        ? AppColors.primary
        : PhaseService.getPhaseColor(phase!.name);
    final divider =
        (isDark ? Colors.white : AppColors.textPrimary).withValues(alpha: 0.08);
    final surface = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.surfaceLight.withValues(alpha: 0.7);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatCell(
                    icon: Icons.calendar_month_outlined,
                    accent: AppColors.primary,
                    value: cycleDay == null ? '—' : _ordinal(cycleDay!),
                    caption: loc.translateWithArgs(
                      'dayOfCycle',
                      {'total': totalDays},
                    ),
                    textMuted: textMuted,
                  ),
                ),
                _divider(divider),
                Expanded(
                  child: _StatCell(
                    icon: phase == null
                        ? Icons.circle_outlined
                        : PhaseService.getPhaseIcon(phase!.name),
                    accent: phaseAccent,
                    value: phase == null ? '—' : phase!.name,
                    caption: loc.translate('currentPhase'),
                    textMuted: textMuted,
                  ),
                ),
              ],
            ),
          ),
          _divider(divider, horizontal: true),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _InfoCell(
                    icon: Icons.water_drop,
                    color: AppColors.period,
                    text: _nextPeriodLabel(),
                    textMuted: textMuted,
                  ),
                ),
                _divider(divider),
                Expanded(
                  child: _InfoCell(
                    icon: Icons.spa_outlined,
                    color: AppColors.fertile,
                    text: _fertileLabel(),
                    textMuted: textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(Color color, {bool horizontal = false}) {
    return horizontal
        ? Divider(height: 1, thickness: 1, color: color)
        : VerticalDivider(width: 1, thickness: 1, color: color);
  }

  String _nextPeriodLabel() {
    if (nextPeriod == null) return loc.translate('noCycleData');
    final days = nextPeriod!.difference(DateTime(
      today.year,
      today.month,
      today.day,
    )).inDays;
    final date = DateFormat('MMM d').format(nextPeriod!);
    if (days <= 0) {
      return '${loc.translate('periodExpected')} · $date';
    }
    return '${loc.translate('In')} $days ${loc.translate('days')} · $date';
  }

  String _fertileLabel() {
    if (ovulation == null || fertile.isEmpty) {
      return loc.translate('fertileWindow');
    }
    final start = DateFormat('MMM d').format(fertile.first);
    final end = DateFormat('MMM d').format(fertile.last);
    return '$start – $end';
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String value;
  final String caption;
  final Color textMuted;

  const _StatCell({
    required this.icon,
    required this.accent,
    required this.value,
    required this.caption,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      color: accent,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              caption,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final Color textMuted;

  const _InfoCell({
    required this.icon,
    required this.color,
    required this.text,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                maxLines: 1,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoDataHint extends StatelessWidget {
  final AppLocalizations loc;
  final Color textMuted;

  const _NoDataHint({required this.loc, required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.translate('welcomeTitle'),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            loc.translate('trackPeriodHint'),
            style: TextStyle(
              color: textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final Color textMuted;

  const _WeekdayHeader({required this.textMuted});

  @override
  Widget build(BuildContext context) {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: textMuted.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime today;
  final Map<String, dynamic> stats;
  final Set<String> periodKeys;
  final List<DateTime> predictedPeriods;
  final List<DateTime> fertile;
  final DateTime? ovulation;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;

  const _MonthGrid({
    required this.month,
    required this.today,
    required this.stats,
    required this.periodKeys,
    required this.predictedPeriods,
    required this.fertile,
    required this.ovulation,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final offset = firstDay.weekday % 7;

    return Column(
      children: [
        for (var row = 0; row < 6; row++)
          Expanded(
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _cell(row * 7 + col, offset, daysInMonth),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(int index, int offset, int daysInMonth) {
    final dayNumber = index - offset + 1;
    final inMonth = dayNumber >= 1 && dayNumber <= daysInMonth;
    final date = DateTime(month.year, month.month, dayNumber);
    final isCurrentMonth = inMonth;
    final isPeriod = periodKeys.contains(_key(date));
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isOvulation =
        ovulation != null && _sameDate(ovulation!, date);
    final isFertile = fertile.any((d) => _sameDate(d, date));
    final isPredicted = predictedPeriods.any((d) => _sameDate(d, date));

    final accent = _accentColor(
      isPeriod: isPeriod,
      isToday: isToday,
      isOvulation: isOvulation,
      isFertile: isFertile,
      isPredicted: isPredicted,
    );
    final fill = accent?.withValues(alpha: isDark ? 0.24 : 0.14);

    final cellIcon = _cellIcon(
      isPeriod: isPeriod,
      isOvulation: isOvulation,
      isFertile: isFertile,
      isPredicted: isPredicted,
    );

    return Container(
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(9),
        border: isToday
            ? Border.all(color: AppColors.today, width: 1.6)
            : isPredicted && !isPeriod
                ? Border.all(
                    color: AppColors.predicted.withValues(alpha: 0.7),
                    width: 1.4,
                  )
                : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              date.day.toString(),
              style: TextStyle(
                color: isCurrentMonth
                    ? (accent ?? textPrimary)
                    : textMuted.withValues(alpha: 0.5),
                fontSize: 12.5,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          if (cellIcon != null && isCurrentMonth)
            Positioned(
              top: 2,
              right: 2.5,
              child: Icon(cellIcon, size: 8.5, color: accent ?? textMuted),
            ),
        ],
      ),
    );
  }

  IconData? _cellIcon({
    required bool isPeriod,
    required bool isOvulation,
    required bool isFertile,
    required bool isPredicted,
  }) {
    if (isPeriod) return Icons.water_drop;
    if (isOvulation) return Icons.wb_sunny;
    if (isFertile) return Icons.spa_outlined;
    if (isPredicted) return Icons.auto_awesome;
    return null;
  }

  Color? _accentColor({
    required bool isPeriod,
    required bool isToday,
    required bool isOvulation,
    required bool isFertile,
    required bool isPredicted,
  }) {
    if (isPeriod) return AppColors.period;
    if (isOvulation) return AppColors.ovulation;
    if (isFertile) return AppColors.fertile;
    if (isPredicted) return AppColors.predicted;
    if (isToday) return AppColors.today;
    return null;
  }

  static bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
