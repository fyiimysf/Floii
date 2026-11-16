import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart' as intl;
import '../../services/cycle/cycle_calculation_service.dart';
import '../../services/cycle/period_log_service.dart';
import '../../services/cycle/prediction_service.dart';
import '../../services/storage/storage_service.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/date_extensions.dart';
import '../../utils/extensions/localization_extension.dart';
import '../../widgets/common/cards.dart';
import '../../widgets/common/cycle_day_cell.dart';
import '../../widgets/common/floating_tab_bar.dart';
import '../../widgets/common/indicators.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/dialogs/clay_confirm_sheet.dart';
import '../home/dialogs/menstrual_settings_dialog.dart';
import '../home/dialogs/period_editor_dialog.dart';
import '../home/widgets/calendar_widget.dart';
import 'package:hugeicons/hugeicons.dart';

/// Whole-year calendar: a vertically scrollable column of compact month
/// grids. Tapping a month drills into the full interactive [MonthDetailScreen].
/// Hosted as a bottom-nav tab and reused by the pushed `/calendar` route.
/// When [showHeader] is true it renders its own floating [FloatingTabBar]
/// (used on the tab); otherwise the caller supplies an app bar.
class CycleYearView extends StatefulWidget {
  final Map<String, dynamic>? stats;
  final bool showHeader;

  const CycleYearView({super.key, this.stats, this.showHeader = false});

  @override
  State<CycleYearView> createState() => CycleYearViewState();
}

class CycleYearViewState extends State<CycleYearView> {
  final StorageService _storage = StorageService();
  final GlobalKey _currentMonthKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  int _year = DateTime.now().year;
  List<DateTime> _predictedPeriods = [];
  Map<String, dynamic>? _lastStats;

  int get _menstrualDays => _storage.getMenstrualDays();

  Map<String, dynamic> get _currentStats =>
      widget.stats ??
      CycleCalculationService.calculateStats(
        _storage.getAllDailyData(),
        defaultCycleLength: _storage.getCycleLength(),
        defaultPeriodLength: _menstrualDays,
      );

  @override
  void initState() {
    super.initState();
    _recomputePredictions();
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToCurrentMonth());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void scrollToCurrentMonth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _currentMonthKey.currentContext;
      if (ctx == null || !_scrollController.hasClients) return;
      final renderObj = ctx.findRenderObject();
      if (renderObj == null) return;
      final viewport = RenderAbstractViewport.of(renderObj);
      final target = viewport.getOffsetToReveal(renderObj, 0.5).offset.clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent,
          );
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _recomputePredictions() {
    final stats = _currentStats;
    final periods = stats['periods'] as List<List<DateTime>>? ?? [];
    _predictedPeriods = [];
    if (periods.isEmpty) return;
    final average = stats['average'] ?? 28;
    DateTime lastPeriod = periods.last.first;
    for (int i = 0; i < 3; i++) {
      lastPeriod = lastPeriod.add(Duration(days: average));
      _predictedPeriods.addAll(List.generate(
        _menstrualDays,
        (index) => lastPeriod.add(Duration(days: index)),
      ));
    }
  }

  void _changeYear(int delta) {
    setState(() {
      _year = _year + delta;
    });
  }

  /// Jump to a specific year (e.g. from a year-picker in the header).
  void jumpToYear(int year) {
    if (year == _year) return;
    setState(() => _year = year);
    scrollToCurrentMonth();
  }

  void _openMonth(DateTime month) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          MonthDetailSheet(month: month, stats: _currentStats),
    );
  }

  void _openYearPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _YearPickerSheet(
        selectedYear: _year,
        currentYear: DateTime.now().year,
        onYearSelected: jumpToYear,
      ),
    );
  }

  void _openCycleHistory() {
    Navigator.of(context).pushNamed(
      '/cycle-history',
      arguments: _currentStats,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _currentStats;
    if (!identical(_lastStats, stats)) {
      _lastStats = stats;
      _recomputePredictions();
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (widget.showHeader)
          // FloatingTabBar(
          //   title: context.tr('calendar'),
          //   accentColor: AppColors.today,
          //   onAction: _openYearPicker,
          //   actionLabel: '$_year',
          //   actionTooltip: context.tr('selectYear'),
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
            leading: IconButton(
              onPressed: _openCycleHistory,
              tooltip: context.tr('cycleHistory'),
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedClock05,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            actions: [
              TextButton(
                  onPressed: _openYearPicker,
                  child: Text(
                    '$_year',
                    style: TextStyle(color: AppColors.today),
                  ))
            ],
            // 2. Optional: Adjusts how content collapses under the status bar
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: FlexibleSpaceBar(
                    // centerTitle: true,
                    title: Text(
                      context.tr('calendar'),
                    ),
                    centerTitle: true,
                  )),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDimensions.sectionSpacing),
                _YearHeader(
                  year: _year,
                  onPrevious: () => _changeYear(-1),
                  onNext: () => _changeYear(1),
                ),
                const SizedBox(height: AppDimensions.elementSpacing),
                for (var m = 1; m <= 12; m++)
                  Padding(
                    key: m == DateTime.now().month ? _currentMonthKey : null,
                    padding: const EdgeInsets.only(
                        bottom: AppDimensions.elementSpacing),
                    child: _MiniMonthCard(
                      month: DateTime(_year, m, 1),
                      stats: stats,
                      predictedPeriods: _predictedPeriods,
                      onTap: () => _openMonth(DateTime(_year, m, 1)),
                    ),
                  ),
                const SizedBox(height: AppDimensions.sectionSpacing * 2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A vertical wheel/dial for picking a year, styled after the date wheel in
/// [ChooseDateSheet]. Scroll to bring a year under the centre band, then
/// confirm to jump the year view to it.
class _YearPickerSheet extends StatefulWidget {
  final int selectedYear;
  final int currentYear;
  final ValueChanged<int> onYearSelected;
  const _YearPickerSheet({
    required this.selectedYear,
    required this.currentYear,
    required this.onYearSelected,
  });

  @override
  State<_YearPickerSheet> createState() => _YearPickerSheetState();
}

class _YearPickerSheetState extends State<_YearPickerSheet> {
  static const int _firstYear = 2000;
  static const int _lastYear = 2100;
  static const double _itemExtent = 56;

  late final FixedExtentScrollController _controller;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.selectedYear;
    _controller = FixedExtentScrollController(
      initialItem: widget.selectedYear - _firstYear,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.pop(context);
    widget.onYearSelected(_selectedYear);
  }

  void _resetToCurrentYear() {
    setState(() => _selectedYear = widget.currentYear);
    _controller.animateToItem(
      widget.currentYear - _firstYear,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      padding: const EdgeInsets.only(top: AppDimensions.elementSpacing),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppDimensions.elementSpacing),
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  context.tr('selectYear'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        right: AppDimensions.smallSpacing),
                    child: IconButton(
                      onPressed: _resetToCurrentYear,
                      tooltip: context.tr('reset'),
                      icon: const Icon(Icons.refresh_rounded),
                      color: AppColors.today,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.smallSpacing),
            _buildDial(theme),
            const SizedBox(height: AppDimensions.elementSpacing),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.cardPadding),
              child: _buildActions(),
            ),
            const SizedBox(height: AppDimensions.elementSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildDial(ThemeData theme) {
    final count = _lastYear - _firstYear + 1;

    return SizedBox(
      height: _itemExtent * 5,
      child: Stack(
        children: [
          // Centre band marking the year currently under the wheel's focus.
          Positioned(
            top: _itemExtent * 2,
            left: AppDimensions.smallSpacing,
            right: AppDimensions.smallSpacing,
            height: _itemExtent,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.today.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color: AppColors.today.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: _itemExtent,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 2.0,
            squeeze: 0.95,
            overAndUnderCenterOpacity: 0.3,
            onSelectedItemChanged: (index) {
              setState(() => _selectedYear = _firstYear + index);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: count,
              builder: (context, index) => _buildYearRow(_firstYear + index),
            ),
          ),
          // Fade the rows into the sheet at the top and bottom edges.
          _buildFade(theme, top: true),
          _buildFade(theme, top: false),
        ],
      ),
    );
  }

  Widget _buildFade(ThemeData theme, {required bool top}) {
    return Positioned(
      left: 0,
      right: 0,
      top: top ? 0 : null,
      bottom: top ? null : 0,
      height: _itemExtent * 2,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: top ? Alignment.topCenter : Alignment.bottomCenter,
              end: top ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYearRow(int year) {
    final theme = Theme.of(context);
    final isCurrent = year == widget.currentYear;

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$year',
            style: TextStyle(
              fontSize: AppDimensions.fontXL,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (isCurrent) ...[
            const SizedBox(width: AppDimensions.smallSpacing),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.today,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
        ),
        const SizedBox(width: AppDimensions.smallSpacing),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.elementSpacing),
            ),
            onPressed: _apply,
            child: Text(
              context.tr('confirm'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _YearHeader extends StatelessWidget {
  final int year;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _YearHeader({
    required this.year,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.calendar_month_outlined,
          color: AppColors.today,
          size: 28,
        ),
        const SizedBox(width: AppDimensions.smallSpacing),
        Expanded(
          child: Text(
            '$year',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ClayButton(
          onTap: onPrevious,
          color: theme.colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.all(10),
          radius: AppDimensions.radiusCircular,
          child: Icon(
            Icons.chevron_left,
            color: theme.colorScheme.onSurface,
            size: AppDimensions.iconMedium,
          ),
        ),
        const SizedBox(width: AppDimensions.smallSpacing),
        ClayButton(
          onTap: onNext,
          color: theme.colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.all(10),
          radius: AppDimensions.radiusCircular,
          child: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface,
            size: AppDimensions.iconMedium,
          ),
        ),
      ],
    );
  }
}

/// A compact, tappable single-month grid for the year overview.
class _MiniMonthCard extends StatelessWidget {
  final DateTime month;
  final Map<String, dynamic> stats;
  final List<DateTime> predictedPeriods;
  final VoidCallback onTap;

  const _MiniMonthCard({
    required this.month,
    required this.stats,
    required this.predictedPeriods,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offset = DateTime(month.year, month.month, 1).weekday % 7;
    const totalCells = 42;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final allPeriodDays = <String>{};
    for (final period in stats['periods'] as List<List<DateTime>>? ?? []) {
      for (final d in period) {
        allPeriodDays.add('${d.year}-${d.month}-${d.day}');
      }
    }

    return ClayCard(
      entranceStep: 0,
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.elementSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  intl.DateFormat('MMMM').format(month),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.smallSpacing),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              final date = _dateForIndex(month, index, offset, daysInMonth);
              final key = '${date.year}-${date.month}-${date.day}';
              return CycleDayCell(
                date: date,
                month: month,
                predictedPeriods: predictedPeriods,
                stats: stats,
                isPeriod: allPeriodDays.contains(key),
              );
            },
          ),
        ],
      ),
    );
  }

  DateTime _dateForIndex(
      DateTime month, int index, int offset, int daysInMonth) {
    if (index < offset) {
      return DateTime(month.year, month.month, 1)
          .subtract(Duration(days: offset - index));
    }
    final day = index - offset + 1;
    if (day > daysInMonth) {
      return DateTime(month.year, month.month + 1, day - daysInMonth);
    }
    return DateTime(month.year, month.month, day);
  }
}

/// Full interactive month view shown as a bottom sheet when a month is tapped
/// in the year overview: grabber + month title row plus month navigation and
/// the shared calendar grid. Drag down to dismiss.
class MonthDetailSheet extends StatefulWidget {
  final DateTime month;
  final Map<String, dynamic> stats;

  const MonthDetailSheet({
    super.key,
    required this.month,
    required this.stats,
  });

  @override
  State<MonthDetailSheet> createState() => _MonthDetailSheetState();
}

class _MonthDetailSheetState extends State<MonthDetailSheet> {
  final StorageService _storage = StorageService();
  List<DateTime> _predictedPeriods = [];
  Map<String, dynamic>? _stats;

  int get _menstrualDays => _storage.getMenstrualDays();

  @override
  void initState() {
    super.initState();
    _stats = widget.stats;
    _recomputePredictions();
  }

  void _recomputePredictions() {
    final stats = _stats ?? widget.stats;
    final periods = stats['periods'] as List<List<DateTime>>? ?? [];
    _predictedPeriods = [];
    if (periods.isEmpty) return;
    final average = stats['average'] ?? 28;
    DateTime lastPeriod = periods.last.first;
    for (int i = 0; i < 3; i++) {
      lastPeriod = lastPeriod.add(Duration(days: average));
      _predictedPeriods.addAll(List.generate(
        _menstrualDays,
        (index) => lastPeriod.add(Duration(days: index)),
      ));
    }
    _stats = stats;
  }

  void _refresh() {
    _stats = CycleCalculationService.calculateStats(
      _storage.getAllDailyData(),
      defaultCycleLength: _storage.getCycleLength(),
      defaultPeriodLength: _menstrualDays,
    );
    _recomputePredictions();
    if (mounted) setState(() {});
  }

  void _handleDateTap(DateTime date, bool isPredicted) {
    if (isPredicted) {
      _confirmPrediction(date);
    } else {
      final data = _storage.getDailyData(date);
      if (data?.isPeriod ?? false) {
        _showPeriodEditor(date);
      } else {
        _askToStartPeriod(date);
      }
    }
  }

  void _askToStartPeriod(DateTime date) {
    final isFirstPeriod = _storage.getPeriodDays().isEmpty;
    if (isFirstPeriod) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        enableDrag: false,
        builder: (context) => MenstrualSettingsDialog(
          initialDays: _menstrualDays,
          initialCycleLength: _storage.getCycleLength(),
          onSave: (days, cycleLength) {
            _storage.setMenstrualDays(days);
            _storage.setCycleLength(cycleLength);
            _markPeriodRange(date, days);
          },
        ),
      );
    } else {
      ClayConfirmSheet.show(
        context,
        title: context.tr('startPeriod'),
        content: context
            .trArgs('startPeriodMessage', {'date': date.format('MMM dd')}),
        icon: Icons.water_drop,
        iconColor: AppColors.period,
        confirmText: context.tr('confirm'),
        onConfirm: () {
          _markPeriodRange(date, _menstrualDays);
        },
      );
    }
  }

  void _confirmPrediction(DateTime date) {
    final predictionStart = _predictedPeriods.firstWhere(
      (d) => d.isSameDate(date),
      orElse: () => DateTime.now(),
    );
    ClayConfirmSheet.show(
      context,
      title: context.tr('confirmPrediction'),
      content: context.trArgs(
          'acceptPredictedPeriod', {'date': predictionStart.format('MMM dd')}),
      icon: Icons.water_drop,
      iconColor: AppColors.predicted,
      confirmText: context.tr('accept'),
      onConfirm: () {
        _markPeriodRange(predictionStart, 7);
      },
    );
  }

  void _showPeriodEditor(DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PeriodEditorDialog(
        initialDate: date,
        defaultMenstrualDays: _menstrualDays,
        onSave: (startDate, duration) {
          _markPeriodRange(startDate, duration);
        },
        onClear: (startDate) {
          _removePeriod(startDate);
        },
      ),
    );
  }

  void _markPeriodRange(DateTime startDate, int duration) {
    PeriodLogService().markRange(startDate, duration);
    _refresh();
  }

  void _removePeriod(DateTime startDate) {
    PeriodLogService().clearRange(startDate);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _stats ?? widget.stats;
    final events = _buildMonthEvents(context, widget.month, stats);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            top: AppDimensions.elementSpacing,
            bottom: AppDimensions.sectionSpacing * 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding),
                child: Row(
                  children: [
                    const Expanded(child: SizedBox.shrink()),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: ClayButton(
                          onTap: () => Navigator.of(context).pop(),
                          color: theme.colorScheme.surfaceContainerHighest,
                          padding: const EdgeInsets.all(10),
                          radius: AppDimensions.radiusCircular,
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedCancel01,
                            color: theme.colorScheme.onSurface,
                            size: AppDimensions.iconMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.elementSpacing),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar03,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: AppDimensions.smallSpacing),
                    Expanded(
                      child: Text(
                        intl.DateFormat('MMMM y').format(widget.month),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.elementSpacing),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding),
                child: CalendarWidget(
                  currentMonth: widget.month,
                  predictedPeriods: _predictedPeriods,
                  stats: stats,
                  onDateTap: _handleDateTap,
                  onDateLongPress: _showPeriodEditor,
                ),
              ),
              if (events.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.sectionSpacing),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.screenPadding),
                  child: SectionHeader(
                    title: context.tr('monthCycleData'),
                    icon: HugeIcons.strokeRoundedRefresh01,
                    color: AppColors.period,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.screenPadding),
                  child: Column(
                    children: [
                      for (final event in events)
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppDimensions.smallSpacing),
                          child: _MonthEventTile(event: event),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<_MonthEvent> _buildMonthEvents(
      BuildContext context, DateTime month, Map<String, dynamic> stats) {
    final events = <_MonthEvent>[];
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    final periods = stats['periods'] as List<List<DateTime>>? ?? [];
    final average = stats['average'] as int? ?? 28;

    for (final p in periods) {
      final start = p.first;
      final end = p.last;
      if (!end.isBefore(monthStart) && !start.isAfter(monthEnd)) {
        events.add(_MonthEvent(
          label: context.tr('period'),
          start: start,
          end: end,
          dayLabel: '${p.length}d',
          color: AppColors.period,
          icon: Icons.water_drop,
        ));
      }
    }

    if (periods.isNotEmpty) {
      final candidates = <DateTime>{for (final p in periods) p.first};

      var projected = periods.last.first;
      var guard = 0;
      while (guard++ < 420) {
        final next = projected.add(Duration(days: average));
        if (next.isAfter(monthEnd)) break;
        candidates.add(next);
        projected = next;
      }

      for (final next in candidates) {
        final fertile = PredictionService.predictFertileWindow(next);
        if (!fertile.last.isBefore(monthStart) &&
            !fertile.first.isAfter(monthEnd)) {
          events.add(_MonthEvent(
            label: context.tr('fertile'),
            start: fertile.first,
            end: fertile.last,
            dayLabel: '${fertile.length}d',
            color: AppColors.fertile,
            icon: Icons.spa_outlined,
          ));
        }
        final ovulation = PredictionService.predictOvulation(next);
        if (!ovulation.isBefore(monthStart) && !ovulation.isAfter(monthEnd)) {
          events.add(_MonthEvent(
            label: context.tr('ovulationPhase'),
            start: ovulation,
            end: ovulation,
            dayLabel: '1d',
            color: AppColors.ovulation,
            icon: Icons.radio_button_checked,
          ));
        }
      }
    }

    events.sort((a, b) => a.start.compareTo(b.start));
    return events;
  }
}

class _MonthEvent {
  final String label;
  final DateTime start;
  final DateTime end;
  final String dayLabel;
  final Color color;
  final IconData icon;

  const _MonthEvent({
    required this.label,
    required this.start,
    required this.end,
    required this.dayLabel,
    required this.color,
    required this.icon,
  });
}

/// A phase row for the month detail sheet: phase icon + name, its date range
/// and a compact duration chip, colored by cycle phase.
class _MonthEventTile extends StatelessWidget {
  final _MonthEvent event;

  const _MonthEventTile({required this.event});

  String get _range {
    final fmt = intl.DateFormat('MMM d');
    return event.start == event.end
        ? fmt.format(event.start)
        : '${fmt.format(event.start)} – ${fmt.format(event.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              color: event.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              event.icon,
              color: event.color,
              size: AppDimensions.iconMedium,
            ),
          ),
          const SizedBox(width: AppDimensions.elementSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.tinySpacing),
                Text(
                  _range,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.smallSpacing),
          PhaseChip(
            label: event.dayLabel,
            color: event.color,
            isActive: true,
          ),
        ],
      ),
    );
  }
}
