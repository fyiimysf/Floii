import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/cycle_models.dart';
import '../services/cycle/cycle_calculation_service.dart';
import '../services/cycle/period_log_service.dart';
import '../services/storage/storage_service.dart';
import '../utils/constants/colors.dart';
import '../utils/constants/dimensions.dart';
import '../utils/extensions/date_extensions.dart';
import '../utils/extensions/localization_extension.dart';
import '../widgets/common/cards.dart';
import '../widgets/common/entrance.dart';
import '../widgets/dialogs/clay_confirm_sheet.dart';
import 'home/dialogs/choose_date_sheet.dart';
import 'home/dialogs/menstrual_settings_dialog.dart';
import 'home/home_screen.dart';
import 'insights/insights_screen.dart';
import 'settings/settings_screen.dart';
import 'calendar/calendar_year_view.dart';
import 'package:hugeicons/hugeicons.dart';

/// Main app shell: bottom navigation bar with a docked center "Add period"
/// FAB. Hosts Home, Calendar, Insights and Settings as persistent tabs. The
/// whole stack rebuilds whenever the daily-data or settings boxes change, so
/// stats and predictions stay fresh after logging.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<CycleYearViewState> _calendarKey =
      GlobalKey<CycleYearViewState>();
  final GlobalKey<InsightsScreenState> _insightsKey =
      GlobalKey<InsightsScreenState>();
  final GlobalKey<SettingsScreenState> _settingsKey =
      GlobalKey<SettingsScreenState>();
  int _index = 0;

  Map<String, dynamic> _computeStats() {
    final storage = StorageService();
    return CycleCalculationService.calculateStats(
      storage.getAllDailyData(),
      defaultCycleLength: storage.getCycleLength(),
      defaultPeriodLength: storage.getMenstrualDays(),
    );
  }

  void _goTo(int index) {
    if (index == _index) {
      switch (index) {
        case 0:
          _homeKey.currentState?.scrollToTop();
        case 1:
          _calendarKey.currentState?.scrollToCurrentMonth();
        case 2:
          _insightsKey.currentState?.scrollToTop();
        case 3:
          _settingsKey.currentState?.scrollToTop();
      }
      return;
    }
    setState(() => _index = index);
    if (index == 1) {
      // the calendar tab just became visible; scroll to the current month
      // after the frame so its viewport is attached and measured.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _calendarKey.currentState?.scrollToCurrentMonth(),
      );
    }
  }

  Future<void> _openAddCycle() async {
    HapticFeedback.mediumImpact();
    final theme = Theme.of(context);
    final today = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
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
                  color: AppColors.period.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedDroplet,
                  color: AppColors.period,
                  size: AppDimensions.iconXL,
                )),
            const SizedBox(height: AppDimensions.elementSpacing),
            Text(
              context.tr('addCycle'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppDimensions.smallSpacing),
            Text(
              context.trArgs(
                  'startPeriodMessage', {'date': today.format('MMM dd')}),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppDimensions.sectionSpacing),
            SizedBox(
              width: double.infinity,
              child: ClayButton(
                color: AppColors.period.withValues(alpha: 0.12),
                radius: AppDimensions.radiusMedium,
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.elementSpacing,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _logPeriodToday();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar02,
                      color: AppColors.period,
                      size: AppDimensions.iconMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('trackToday'),
                      style: const TextStyle(
                        color: AppColors.period,
                        fontWeight: FontWeight.w700,
                        fontSize: AppDimensions.fontMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.elementSpacing),
            SizedBox(
              width: double.infinity,
              child: ClayButton(
                color: AppColors.predicted.withValues(alpha: 0.12),
                radius: AppDimensions.radiusMedium,
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.elementSpacing,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickDateThenLog();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendarAdd01,
                      color: AppColors.predicted,
                      size: AppDimensions.iconMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('chooseDate'),
                      style: const TextStyle(
                        color: AppColors.predicted,
                        fontWeight: FontWeight.w700,
                        fontSize: AppDimensions.fontMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.elementSpacing),
          ],
        ),
      ),
    );
  }

  void _logPeriodToday() {
    final storage = StorageService();
    final now = DateTime.now();

    if (storage.getPeriodDays().isEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MenstrualSettingsDialog(
          initialDays: storage.getMenstrualDays(),
          initialCycleLength: storage.getCycleLength(),
          onSave: (days, cycleLength) {
            storage.setMenstrualDays(days);
            storage.setCycleLength(cycleLength);
            PeriodLogService().markRange(now, days);
          },
        ),
      );
    } else {
      ClayConfirmSheet.show(
        context,
        title: context.tr('startPeriod'),
        content: context
            .trArgs('startPeriodMessage', {'date': now.format('MMM dd')}),
        icon: Icons.water_drop,
        iconColor: AppColors.period,
        confirmText: context.tr('confirm'),
        onConfirm: () {
          PeriodLogService().markRange(now, storage.getMenstrualDays());
        },
      );
    }
  }

  void _pickDateThenLog() {
    final storage = StorageService();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChooseDateSheet(
        initialDate: DateTime.now(),
        defaultMenstrualDays: storage.getMenstrualDays(),
        onSave: (startDate, duration) {
          PeriodLogService().markRange(startDate, duration);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([
        Hive.box<DailyData>('dailyData').listenable(),
        Hive.box<int>('settings').listenable(),
      ]),
      builder: (context, child) {
        final stats = _computeStats();

        return Scaffold(
          // IndexedStack keeps every tab alive so switching costs nothing, but
          // it also means the swap is instantaneous and lifeless. Each tab fades
          // and rises on the way in; the wrapper keeps the tab's own state
          // because it sits inside the retained child rather than replacing it.
          body: IndexedStack(
            index: _index,
            children: [
              EntranceOnActivate(
                isActive: _index == 0,
                child: HomeScreen(
                  key: _homeKey,
                  stats: stats,
                  onOpenInsights: () => _goTo(2),
                ),
              ),
              EntranceOnActivate(
                isActive: _index == 1,
                child: CycleYearView(
                    key: _calendarKey, stats: stats, showHeader: true),
              ),
              EntranceOnActivate(
                isActive: _index == 2,
                child: InsightsScreen(key: _insightsKey, stats: stats),
              ),
              EntranceOnActivate(
                isActive: _index == 3,
                child: SettingsScreen(key: _settingsKey),
              ),
            ],
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(top: 32),
            child: _AddCycleFab(onTap: _openAddCycle),
          ),
          bottomNavigationBar: Skeleton.keep(child: _buildBottomNav(theme)),
        );
      },
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    final borderColor = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : theme.colorScheme.outline.withValues(alpha: 0.2);

    return Container(
      key: const Key('shellBottomNav'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavItem(
                icon: HugeIcons.strokeRoundedHome06,
                label: context.tr('home'),
                accent: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.primaryDark
                    : AppColors.primaryAccent,
                selected: _index == 0,
                onTap: () => _goTo(0),
              ),
              _NavItem(
                icon: HugeIcons.strokeRoundedCalendar03,
                label: context.tr('calendar'),
                accent: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.primaryDark
                    : AppColors.primaryAccent,
                selected: _index == 1,
                onTap: () => _goTo(1),
              ),
              const SizedBox(width: 78),
              _NavItem(
                icon: HugeIcons.strokeRoundedAnalytics02,
                label: context.tr('insights'),
                accent: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.primaryDark
                    : AppColors.primaryAccent,
                selected: _index == 2,
                onTap: () => _goTo(2),
              ),
              _NavItem(
                icon: HugeIcons.strokeRoundedSetting07,
                label: context.tr('settings'),
                accent: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.primaryDark
                    : AppColors.primaryAccent,
                selected: _index == 3,
                onTap: () => _goTo(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCycleFab extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCycleFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.tr('addCycle'),
      child: SizedBox(
        width: 68,
        height: 68,
        child: ClayButton(
          onTap: onTap,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.primaryDark
              : AppColors.primaryAccent,
          radius: 18,
          padding: EdgeInsets.zero,
          child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.surfaceCream.withValues(alpha: 0.35),
                  width: 4,
                ),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedPlusSign,
                size: 10,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceCream.withValues(alpha: 0.85)
                    : AppColors.surfaceLight,
              )),
        ),
      ),
    );
  }
}

/// Height of a nav label box. Matches fontSize 12 at height 1.25, so labels sit
/// on one line and every tab keeps the same total height.
const double _kNavLabelHeight = 15;

class _NavItem extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dimColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);
    final selectColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircular),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.tinySpacing,
            vertical: 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOut,
                width: 46,
                height: selected ? 32 : 28,
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.45)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusCircular),
                ),
                child: HugeIcon(
                  icon: icon,
                  size: 30,
                  color: selected ? selectColor : dimColor,
                ),
              ),
              const SizedBox(height: 1),
              // Fixed height, single line, shrink to fit. A label that wraps
              // (German "Einstellungen" is long enough to) makes this item
              // taller than its siblings, and because the bar centres items
              // vertically that pushes this tab's icon up out of line with the
              // others. Locking the box keeps every tab the same height, and
              // scaling down means a long word is still readable rather than
              // being cut off.
              SizedBox(
                height: _kNavLabelHeight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                      color: selected ? selectColor : dimColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
