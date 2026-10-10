import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../models/cycle_models.dart';
import '../../models/enums.dart';
import '../../services/cycle/cycle_calculation_service.dart';
import '../../services/storage/storage_service.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/date_extensions.dart';
import '../../utils/extensions/localization_extension.dart';
import '../../widgets/common/cards.dart';
import 'widgets/calendar_widget.dart';
import 'widgets/cycle_status_card.dart';
import 'dialogs/period_editor_dialog.dart';
import 'dialogs/menstrual_settings_dialog.dart';
import 'dialogs/mood_picker_sheet.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? stats;
  final VoidCallback? onOpenInsights;

  const HomeScreen({super.key, this.stats, this.onOpenInsights});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final ScrollController _scrollController = ScrollController();
  DateTime _currentMonth = DateTime.now();
  int _monthPage = monthPageIndex(DateTime.now());
  bool _statusCollapsed = false;
  late final PageController _monthPageController;
  List<DateTime> _predictedPeriods = [];
  Map<String, dynamic>? _lastStats;

  int get _menstrualDays => _storage.getMenstrualDays();

  Map<String, dynamic> get _computedStats {
    return CycleCalculationService.calculateStats(
      _storage.getAllDailyData(),
      defaultCycleLength: _storage.getCycleLength(),
      defaultPeriodLength: _menstrualDays,
    );
  }

  @override
  void initState() {
    super.initState();
    _monthPageController = PageController(initialPage: _monthPage);
    _recomputePredictions();
  }

  @override
  void dispose() {
    _monthPageController.dispose();
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

  void _recomputePredictions() {
    final stats = widget.stats ?? _computedStats;
    final periods = stats['periods'] as List<List<DateTime>>;

    if (periods.isEmpty) {
      _predictedPeriods = [];
      return;
    }

    final average = stats['average'] ?? 28;
    _predictedPeriods = [];

    DateTime lastPeriod = periods.last.first;
    for (int i = 0; i < 3; i++) {
      lastPeriod = lastPeriod.add(Duration(days: average));
      _predictedPeriods.addAll(List.generate(
        _menstrualDays,
        (index) => lastPeriod.add(Duration(days: index)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats ?? _computedStats;

    if (!identical(_lastStats, stats)) {
      _lastStats = stats;
      _recomputePredictions();
    }

    final now = DateTime.now();
    final isCurrentMonthShowing =
        _currentMonth.year == now.year && _currentMonth.month == now.month;

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          // snap: true,
          // floating: true,
          expandedHeight: 70,
          stretch: true,
          surfaceTintColor: Theme.of(context).colorScheme.primaryContainer,
          backgroundColor: Colors.transparent,
          // scrolledUnderElevation: 0,
          actions: [
            // if (!isCurrentMonthShowing)
            Visibility(
              visible: !isCurrentMonthShowing,
              child: Padding(
                padding: const EdgeInsetsGeometry.symmetric(horizontal: 12.0),
                child: IconButton(
                  onPressed: _goToToday,
                  tooltip: context.tr('goToToday'),
                  icon: Icon(Icons.subdirectory_arrow_left_rounded),
                  iconSize: 26,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                onPressed: () => Navigator.of(context).pushNamed('/learn'),
                tooltip: context.tr('learn'),
                icon: const Icon(Icons.menu_book_rounded, size: 26),
              ),
            ),
          ],
          flexibleSpace: Skeleton.keep(
            child: ClipRect(
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: FlexibleSpaceBar(
                    // centerTitle: true,
                    title: Text(
                      'Floii',
                    ),
                    titlePadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  )),
            ),
          ),
        ),

        // FloatingTabBar(
        //   title: context.tr('Floii'),
        //   accentColor: AppColors.primary,
        //   showAction: !isCurrentMonthShowing,
        //   onAction: _goToToday,
        //   actionLabel: context.tr('today'),
        //   actionTooltip: context.tr('goToToday'),
        // ),
        // const SliverToBoxAdapter(
        //   child: SizedBox(height: AppDimensions.smallSpacing * 2),
        // ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding / 1.5),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                AnimatedSize(
                  duration: AppDimensions.durationBounce,
                  curve: AppDimensions.curveClay,
                  alignment: Alignment.topCenter,
                  child: CycleStatusCard(
                    stats: stats,
                    onTap: () => _showInsights(context, stats),
                    collapsed: _statusCollapsed,
                    currentMood: _storage.getMoodForDate(now),
                    onMoodTap: _showMoodPicker,
                    onToggleCollapsed: () => setState(() {
                      _statusCollapsed = !_statusCollapsed;
                    }),
                  ),
                ),
                const SizedBox(height: AppDimensions.elementSpacing),
                CalendarWidget(
                  currentMonth: _currentMonth,
                  predictedPeriods: _predictedPeriods,
                  stats: stats,
                  pageController: _monthPageController,
                  onPageChanged: _onMonthPageChanged,
                  onPreviousMonth: () => _changeMonth(-1),
                  onNextMonth: () => _changeMonth(1),
                  onDateTap: _handleDateTap,
                  onDateLongPress: _showPeriodEditor,
                ),
                const SizedBox(height: AppDimensions.sectionSpacing),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _logMoodForToday(Mood mood) async {
    await _storage.setMoodForDate(DateTime.now(), mood);
    if (mounted) setState(() {});
  }

  /// Mood selection lives in its own sheet, opened from the status card's mood
  /// button, instead of a permanent card in the scroll view.
  Future<void> _showMoodPicker() async {
    final mood = await showModalBottomSheet<Mood>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MoodPickerSheet(
        selected: _storage.getMoodForDate(DateTime.now()),
      ),
    );
    if (mood != null) await _logMoodForToday(mood);
  }

  void _goToToday() {
    final target = monthPageIndex(DateTime.now());
    final current = _monthPageController.hasClients
        ? (_monthPageController.page?.round() ?? _monthPage)
        : _monthPage;
    // Large jumps are unreliable when animated in a single flight (pages fly
    // by too fast to settle). Snap the title for anything more than a screen
    // or two; the calendar grid still animates into place.
    if ((target - current).abs() > 6) {
      _monthPageController.jumpToPage(target);
    } else {
      _animateToPage(target);
    }
    setState(() {
      _currentMonth = DateTime.now();
      _monthPage = target;
    });
    // scrollToTop();
  }

  void _changeMonth(int delta) {
    _animateToPage(_monthPage + delta);
  }

  void _animateToPage(int page) {
    if (!_monthPageController.hasClients) return;
    _monthPageController.animateToPage(
      page,
      duration: AppDimensions.durationBounce,
      curve: AppDimensions.curveClay,
    );
  }

  void _onMonthPageChanged(int index) {
    setState(() {
      _monthPage = index;
      _currentMonth = monthFromPageIndex(index);
    });
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
      _showClayDialog(
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

    _showClayDialog(
      title: context.tr('confirmPrediction'),
      content: context.trArgs(
          'acceptPredictedPeriod', {'date': predictionStart.format('MMM dd')}),
      icon: Icons.auto_awesome,
      iconColor: AppColors.predicted,
      confirmText: context.tr('accept'),
      onConfirm: () {
        _markPeriodRange(predictionStart, 7);
      },
    );
  }

  void _showClayDialog({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXL),
          ),
        ),
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
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
            Container(
              padding: const EdgeInsets.all(AppDimensions.elementSpacing),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: AppDimensions.iconXL,
              ),
            ),
            const SizedBox(height: AppDimensions.elementSpacing),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimensions.smallSpacing),
            Text(
              content,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppDimensions.sectionSpacing),
            Row(
              children: [
                Expanded(
                  child: ClayButton(
                    onTap: () => Navigator.pop(context),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : theme.colorScheme.surfaceContainerHighest,
                    child: Text(
                      context.tr('cancel'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.elementSpacing),
                Expanded(
                  child: ClayButton(
                    onTap: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    color: iconColor.withValues(alpha: 0.1),
                    child: Text(
                      confirmText,
                      style: TextStyle(
                        color: iconColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.elementSpacing),
          ],
        ),
      ),
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
    for (int i = 0; i < duration; i++) {
      final date = startDate.addDays(i);
      final data = _storage.getDailyData(date) ?? DailyData(date: date);
      data.isPeriod = true;
      _storage.saveDailyData(date, data);
    }
    _recomputePredictions();
    setState(() {});
  }

  void _removePeriod(DateTime startDate) {
    for (int i = 0; i < 7; i++) {
      final date = startDate.addDays(i);
      final data = _storage.getDailyData(date);
      if (data != null) {
        data.isPeriod = false;
        _storage.saveDailyData(date, data);
      }
    }
    _recomputePredictions();
    setState(() {});
  }

  void _showInsights(BuildContext context, Map<String, dynamic> stats) {
    if (widget.onOpenInsights != null) {
      widget.onOpenInsights!();
    } else {
      Navigator.pushNamed(context, '/insights', arguments: stats);
    }
  }
}
