import 'package:flutter/material.dart';
import '../../services/cycle/prediction_service.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/date_extensions.dart';

/// A single calendar day cell colored by cycle phase, shared by the home month
/// grid and the compact month grids in the year overview. Mirrors the phase
/// palette of [PhaseService]: period, fertile, ovulation and follicular fill
/// with a phase-colored icon, predicted dates get a sparkle badge and the
/// current day a soft blue ring.
class CycleDayCell extends StatefulWidget {
  final DateTime date;
  final DateTime month;
  final List<DateTime> predictedPeriods;
  final Map<String, dynamic> stats;
  final bool isPeriod;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CycleDayCell({
    super.key,
    required this.date,
    required this.month,
    required this.predictedPeriods,
    required this.stats,
    this.isPeriod = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<CycleDayCell> createState() => _CycleDayCellState();
}

class _CycleDayCellState extends State<CycleDayCell> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isToday = widget.date.isToday();
    final isCurrentMonth = widget.date.month == widget.month.month;
    final isPredicted =
        widget.predictedPeriods.any((d) => d.isSameDate(widget.date));

    final prediction = widget.stats['prediction'] as DateTime?;
    final fertileDates = prediction != null
        ? PredictionService.predictFertileWindow(prediction)
        : <DateTime>[];
    final ovulationDate = prediction != null
        ? PredictionService.predictOvulation(prediction)
        : null;

    final isFertile = fertileDates.any((d) => d.isSameDate(widget.date));
    final isOvulation =
        ovulationDate != null && ovulationDate.isSameDate(widget.date);

    final isFollicular =
        _isInFollicularPhase(widget.date, widget.stats, fertileDates);

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.calendarCellGap),
        decoration: BoxDecoration(
          color: _getBackgroundColor(isPeriod, isOvulation, isFertile,
              isFollicular, isPredicted, isToday, isDark),
          borderRadius: BorderRadius.circular(AppDimensions.radiusCell),
          border: _getBorder(isPeriod, isOvulation, isFertile, isFollicular,
              isPredicted, isToday),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : AppColors.clayShadow.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                    spreadRadius: -1,
                  ),
                ]
              : _getShadow(isPeriod, isOvulation, isFertile, isFollicular,
                  isToday, isDark),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 4,
              bottom: 3,
              child: SizedBox(
                width: 24,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    widget.date.day.toString(),
                    style: TextStyle(
                      color: _getTextColor(isCurrentMonth, isOvulation,
                          isFertile, isFollicular, isToday, isPeriod, isDark),
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                      fontSize: AppDimensions.fontMedium,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: _buildTopRightIcon(
                      theme, isPeriod, isOvulation, isFertile, isPredicted) ??
                  const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  bool get isPeriod => widget.isPeriod;

  Widget? _buildTopRightIcon(ThemeData theme, bool isPeriod, bool isOvulation,
      bool isFertile, bool isPredicted) {
    IconData icon;
    Color color;
    double size = 12;
    if (isPeriod) {
      icon = Icons.water_drop;
      color = AppColors.period;
    } else if (isOvulation) {
      icon = Icons.wb_sunny;
      color = AppColors.ovulation;
      size = 13;
    } else if (isFertile) {
      icon = Icons.spa_outlined;
      color = AppColors.fertile;
    } else if (isPredicted) {
      icon = Icons.auto_awesome;
      color = AppColors.predicted;
    } else {
      return null;
    }
    return Icon(icon, size: size, color: color);
  }

  Color _getBackgroundColor(bool isPeriod, bool isOvulation, bool isFertile,
      bool isFollicular, bool isPredicted, bool isToday, bool isDark) {
    if (isPeriod) return AppColors.period.withOpacity(0.15);
    if (isOvulation) return AppColors.ovulation.withOpacity(0.2);
    if (isFertile) return AppColors.fertile.withOpacity(0.1);
    if (isFollicular) return AppColors.follicular.withOpacity(0.1);
    if (isPredicted) return AppColors.predicted.withOpacity(0.08);
    if (isToday) return AppColors.today.withOpacity(0.1);
    return isDark ? Colors.transparent : theme.colorScheme.surface;
  }

  Border _getBorder(bool isPeriod, bool isOvulation, bool isFertile,
      bool isFollicular, bool isPredicted, bool isToday) {
    if (isOvulation) return Border.all(color: AppColors.ovulation, width: 2);
    if (isPeriod) {
      return Border.all(color: AppColors.period.withOpacity(0.5), width: 2);
    }
    if (isFertile) {
      return Border.all(color: AppColors.fertile.withOpacity(0.5), width: 0);
    }
    if (isFollicular) {
      return Border.all(color: AppColors.follicular.withOpacity(0.5), width: 1);
    }
    if (isPredicted) {
      return Border.all(color: AppColors.predicted.withOpacity(0.8), width: 2);
    }
    if (isToday) return Border.all(color: AppColors.today, width: 2);
    return Border.all(color: theme.colorScheme.outline.withOpacity(0), width: 1);
  }

  List<BoxShadow> _getShadow(bool isPeriod, bool isOvulation, bool isFertile,
      bool isFollicular, bool isToday, bool isDark) {
    if (isDark) {
      return [];
    }

    if (isPeriod || isToday) {
      return [
        BoxShadow(
          color:
              (isPeriod ? AppColors.period : AppColors.today).withOpacity(0.15),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];
    }

    return [
      BoxShadow(
        color: AppColors.clayShadow.withOpacity(0.1),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ];
  }

  Color _getTextColor(bool isCurrentMonth, bool isOvulation, bool isFertile,
      bool isFollicular, bool isToday, bool isPeriod, bool isDark) {
    if (!isCurrentMonth) return theme.colorScheme.onSurface.withOpacity(0.3);
    if (isOvulation) return AppColors.ovulation;
    if (isFertile) return AppColors.fertile;
    if (isFollicular) return AppColors.follicular;
    if (isToday) return AppColors.today;
    if (isPeriod) return AppColors.period;
    return theme.colorScheme.onSurface;
  }

  bool _isInFollicularPhase(
      DateTime date, Map<String, dynamic> stats, List<DateTime> fertileDates) {
    if (fertileDates.isEmpty) return false;

    final periods = stats['periods'] as List<List<DateTime>>? ?? [];
    if (periods.isEmpty) return false;

    final lastPeriod = periods.last;
    final lastPeriodEnd = lastPeriod.last;
    final averageCycle = stats['average'] as int? ?? 28;
    final now = DateTime.now();

    final daysSinceLastPeriod = now.difference(lastPeriod.first).inDays;
    DateTime periodEnd;
    DateTime fertileStart = fertileDates.first;

    if (daysSinceLastPeriod > averageCycle) {
      final cyclesPassed = daysSinceLastPeriod ~/ averageCycle;
      final predictedCycleStart = lastPeriod.first.add(
        Duration(days: cyclesPassed * averageCycle),
      );
      final periodLength = stats['currentPeriodLength'] as int? ?? 5;
      periodEnd = predictedCycleStart.add(Duration(days: periodLength - 1));

      final predictedNextPeriod =
          predictedCycleStart.add(Duration(days: averageCycle));
      fertileStart = predictedNextPeriod.subtract(const Duration(days: 14 + 5));
    } else {
      periodEnd = lastPeriodEnd;
    }

    final dayAfterPeriod = periodEnd.add(const Duration(days: 1));
    final dayBeforeFertile = fertileStart.subtract(const Duration(days: 1));

    return !date.isBefore(dayAfterPeriod) && !date.isAfter(dayBeforeFertile);
  }

  ThemeData get theme => Theme.of(context);
}