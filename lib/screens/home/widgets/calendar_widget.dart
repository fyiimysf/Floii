import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/cycle/phase_service.dart';
import '../../../services/storage/storage_service.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/dimensions.dart';
import '../../../utils/extensions/date_extensions.dart';
import '../../../utils/extensions/localization_extension.dart';
import '../../../widgets/common/cards.dart';
import '../../../widgets/common/cycle_day_cell.dart';

int monthPageIndex(DateTime month) =>
    (month.year - 1900) * 12 + (month.month - 1);

DateTime monthFromPageIndex(int index) {
  final year = 1900 + (index / 12).floor();
  final month = ((index % 12) + 12) % 12 + 1;
  return DateTime(year, month, 1);
}

class CalendarWidget extends StatefulWidget {
  final DateTime? currentMonth;
  final List<DateTime> predictedPeriods;
  final Function(DateTime date, bool isPredicted) onDateTap;
  final Function(DateTime date) onDateLongPress;
  final Map<String, dynamic> stats;
  final PageController? pageController;
  final ValueChanged<int>? onPageChanged;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;

  const CalendarWidget({
    super.key,
    this.currentMonth,
    required this.predictedPeriods,
    required this.onDateTap,
    required this.onDateLongPress,
    required this.stats,
    this.pageController,
    this.onPageChanged,
    this.onPreviousMonth,
    this.onNextMonth,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _displayMonth;
  late final PageController _gridController;

  @override
  void initState() {
    super.initState();
    _displayMonth = widget.currentMonth ?? DateTime.now();
    _gridController =
        PageController(initialPage: monthPageIndex(_displayMonth));
    widget.pageController?.addListener(_syncGridOnTitleSettle);
  }

  @override
  void dispose() {
    widget.pageController?.removeListener(_syncGridOnTitleSettle);
    _gridController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pageController != oldWidget.pageController) {
      oldWidget.pageController?.removeListener(_syncGridOnTitleSettle);
      widget.pageController?.addListener(_syncGridOnTitleSettle);
    }
    if (widget.currentMonth != null &&
        widget.currentMonth != oldWidget.currentMonth) {
      _displayMonth = widget.currentMonth!;
    }
  }

  void _jumpToMonth(DateTime target) {
    if (!target.isSameMonth(_displayMonth)) {
      setState(() => _displayMonth = target);
    }
  }

  void _syncGridOnTitleSettle() {
    final title = widget.pageController;
    if (title == null || !title.hasClients) return;
    if (title.position.isScrollingNotifier.value) return;
    final page = title.page?.round();
    if (page != null) {
      _animateGridTo(page);
    }
  }

  Widget _buildGrid(DateTime month, bool isPaged) {
    if (!isPaged) {
      return _MonthGrid(
        month: month,
        predictedPeriods: widget.predictedPeriods,
        stats: widget.stats,
        onDateTap: widget.onDateTap,
        onDateLongPress: widget.onDateLongPress,
      );
    }
    return PageView.builder(
      key: const ValueKey('calendarMonthGrid'),
      controller: _gridController,
      onPageChanged: _onGridPageChanged,
      itemBuilder: (context, index) {
        final pageMonth = monthFromPageIndex(index);
        return _MonthGrid(
          month: pageMonth,
          predictedPeriods: widget.predictedPeriods,
          stats: widget.stats,
          onDateTap: widget.onDateTap,
          onDateLongPress: widget.onDateLongPress,
        );
      },
    );
  }

  void _onGridPageChanged(int index) {
    _jumpToMonth(monthFromPageIndex(index));
    final title = widget.pageController;
    if (title != null &&
        title.hasClients &&
        !title.position.isScrollingNotifier.value) {
      final current = title.page?.round();
      if (current != index) {
        title.jumpToPage(index);
      }
    }
    widget.onPageChanged?.call(index);
  }

  void _animateGridTo(int index) {
    if (!_gridController.hasClients) return;
    if (_gridController.position.isScrollingNotifier.value) return;
    if (_gridController.page?.round() == index) return;
    _gridController.animateToPage(
      index,
      duration: AppDimensions.durationBounce,
      curve: AppDimensions.curveClay,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final month = _displayMonth;
    final isPaged = widget.pageController != null;

    final Widget grid = _buildGrid(month, isPaged);

    Widget card = ClayCard(
      padding: const EdgeInsets.all(AppDimensions.calendarGridPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (isPaged) ...[
                Expanded(
                  flex: 1,
                  child: _AdjacentMonthChip(
                    month: DateTime(month.year, month.month - 1, 1),
                    onTap: () {
                      final target = DateTime(month.year, month.month - 1, 1);
                      _jumpToMonth(target);
                      _animateGridTo(monthPageIndex(target));
                      widget.onPreviousMonth?.call();
                    },
                    isDark: isDark,
                    isNext: false,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: AppDimensions.smallSpacing),
              ],
              Expanded(
                flex: isPaged ? 3 : 4,
                child: isPaged
                    ? SizedBox(
                        height: AppDimensions.buttonHeightSmall,
                        child: PageView.builder(
                          key: const ValueKey('calendarMonthTitle'),
                          controller: widget.pageController,
                          onPageChanged: (index) {
                            final target = monthFromPageIndex(index);
                            _jumpToMonth(target);
                            _animateGridTo(index);
                            widget.onPageChanged?.call(index);
                          },
                          itemBuilder: (_, index) {
                            final pageMonth = monthFromPageIndex(index);
                            return Center(
                              child: _MonthTitleChip(
                                label: DateFormat('MMMM y').format(pageMonth),
                                theme: theme,
                              ),
                            );
                          },
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(
                            left: AppDimensions.tinySpacing),
                        child: _MonthTitleChip(
                          label: DateFormat('MMMM y').format(month),
                          theme: theme,
                        ),
                      ),
              ),
              if (isPaged) ...[
                const SizedBox(width: AppDimensions.smallSpacing),
                Expanded(
                  flex: 1,
                  child: _AdjacentMonthChip(
                    month: DateTime(month.year, month.month + 1, 1),
                    onTap: () {
                      final target = DateTime(month.year, month.month + 1, 1);
                      _jumpToMonth(target);
                      _animateGridTo(monthPageIndex(target));
                      widget.onNextMonth?.call();
                    },
                    isDark: isDark,
                    isNext: true,
                    theme: theme,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(
            height: isPaged
                ? AppDimensions.elementSpacing
                : AppDimensions.smallSpacing,
          ),
          _WeekdayHeader(
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: AppDimensions.tinySpacing),
          AspectRatio(
            aspectRatio: 7 / 6,
            child: grid,
          ),
          const SizedBox(height: AppDimensions.elementSpacing),
          if (PhaseService.currentCycleFromStats(widget.stats) == null) ...[
            _buildLegend(context),
            const SizedBox(height: AppDimensions.smallSpacing + 2),
          ],
        ],
      ),
    );

    return card;
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.smallSpacing),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LegendItem(
              icon: Icons.water_drop,
              color: AppColors.period,
              label: context.tr('period'),
            ),
            const SizedBox(width: AppDimensions.elementSpacing),
            _LegendItem(
              icon: Icons.spa_outlined,
              color: AppColors.fertile,
              label: context.tr('fertile'),
            ),
            const SizedBox(width: AppDimensions.elementSpacing),
            _LegendItem(
              icon: Icons.wb_sunny,
              color: AppColors.ovulation,
              label: context.tr('ovulationPhase'),
            ),
            const SizedBox(width: AppDimensions.elementSpacing),
            _LegendItem(
              icon: Icons.auto_awesome,
              color: AppColors.predicted,
              label: context.tr('predicted'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthTitleChip extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _MonthTitleChip({
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.elementSpacing,
        vertical: AppDimensions.smallSpacing,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        // border: Border.all(
        //   color: theme.colorScheme.outline.withValues(alpha: 0.15),
        // ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AdjacentMonthChip extends StatelessWidget {
  final DateTime month;
  final VoidCallback? onTap;
  final bool isDark;
  final bool isNext;
  final ThemeData theme;

  const _AdjacentMonthChip({
    required this.month,
    required this.onTap,
    required this.isDark,
    required this.isNext,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final surface = theme.colorScheme.surface;
    final colors = isDark
        ? [
            surface,
            Color.lerp(surface, Colors.black, 0.10)!,
          ]
        : [
            Color.lerp(surface, Colors.black, 0.03)!,
            Color.lerp(surface, Colors.black, 0.06)!,
          ];
    final chevron = isNext ? Icons.chevron_right : Icons.chevron_left;
    final chevronColor = theme.colorScheme.onSurface.withValues(alpha: 0.75);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppDimensions.buttonHeightSmall,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isNext) ...[
                Icon(chevron, size: 20, color: chevronColor),
                const SizedBox(width: 2),
              ],
              Text(
                DateFormat('MMM').format(month),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isNext) ...[
                const SizedBox(width: 2),
                Icon(chevron, size: 20, color: chevronColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;

  const _WeekdayHeader({required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sunday =
        DateTime.now().subtract(Duration(days: DateTime.now().weekday % 7));
    final weekdays = List.generate(7, (index) {
      final day = sunday.add(Duration(days: index));
      return DateFormat.E().format(day)[0];
    });

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.smallSpacing,
        vertical: AppDimensions.tinySpacing,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekdays
            .map((day) => Text(
                  day,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w700,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final List<DateTime> predictedPeriods;
  final Map<String, dynamic> stats;
  final Function(DateTime date, bool isPredicted) onDateTap;
  final Function(DateTime date) onDateLongPress;

  const _MonthGrid({
    required this.month,
    required this.predictedPeriods,
    required this.stats,
    required this.onDateTap,
    required this.onDateLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;
    final sundayBasedOffset = firstDay.weekday % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final date = _calculateDateForIndex(
            index, firstDay, daysInMonth, sundayBasedOffset);
        final isPeriod = StorageService().getDailyData(date)?.isPeriod ?? false;
        return CycleDayCell(
          date: date,
          month: month,
          predictedPeriods: predictedPeriods,
          stats: stats,
          isPeriod: isPeriod,
          onTap: () => onDateTap(date, _isPredictedDate(date)),
          onLongPress: () => onDateLongPress(date),
        );
      },
    );
  }

  DateTime _calculateDateForIndex(
    int index,
    DateTime firstDay,
    int daysInMonth,
    int weekdayOffset,
  ) {
    if (index < weekdayOffset) {
      return firstDay.subtract(Duration(days: weekdayOffset - index));
    }
    final day = index - weekdayOffset + 1;
    if (day > daysInMonth) {
      return DateTime(firstDay.year, firstDay.month + 1, day - daysInMonth);
    }
    return DateTime(firstDay.year, firstDay.month, day);
  }

  bool _isPredictedDate(DateTime date) {
    return predictedPeriods.any((d) => d.isSameDate(date));
  }
}

class _LegendItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _LegendItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
