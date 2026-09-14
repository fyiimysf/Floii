import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cycle_models.dart';
import '../services/cycle/cycle_calculation_service.dart';
import '../services/cycle/period_log_service.dart';
import '../services/storage/storage_service.dart';
import '../utils/constants/colors.dart';
import '../utils/constants/dimensions.dart';
import '../utils/extensions/date_extensions.dart';
import '../utils/extensions/localization_extension.dart';
import '../widgets/common/cards.dart';
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
      defaultCycleLength: 28,
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
              Container(
                padding: const EdgeInsets.all(AppDimensions.elementSpacing),
                decoration: BoxDecoration(
                  color: AppColors.period.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(icon: HugeIcons.strokeRoundedDroplet,
                  color: AppColors.period,
                  size: AppDimensions.iconXL,
                )
              ),
              const SizedBox(height: AppDimensions.elementSpacing),
              Text(
                context.tr('addCycle'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppDimensions.smallSpacing),
              Text(
                context.trArgs('startPeriodMessage',
                    {'date': today.format('MMM dd')}),
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
                      HugeIcon(icon: HugeIcons.strokeRoundedCalendar02,
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
                      HugeIcon(icon: HugeIcons.strokeRoundedCalendarAdd01,
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
          onSave: (days) {
            storage.setMenstrualDays(days);
            PeriodLogService().markRange(now, days);
          },
        ),
      );
    } else {
      ClayConfirmSheet.show(
        context,
        title: context.tr('startPeriod'),
        content: context.trArgs(
            'startPeriodMessage', {'date': now.format('MMM dd')}),
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
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _index,
              children: [
                HomeScreen(
                  key: _homeKey,
                  stats: stats,
                  onOpenInsights: () => _goTo(2),
                ),
                CycleYearView(key: _calendarKey, stats: stats, showHeader: true),
                InsightsScreen(key: _insightsKey, stats: stats),
                SettingsScreen(key: _settingsKey),
              ],
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _AddCycleFab(onTap: _openAddCycle),
          ),
          bottomNavigationBar: _buildBottomNav(theme),
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
            children: [
              _NavItem(
                icon: HugeIcons.strokeRoundedHome06,
                label: context.tr('home'),
                accent: AppColors.primary,
                selected: _index == 0,
                onTap: () => _goTo(0),
              ),
              _NavItem(
                icon: HugeIcons.strokeRoundedCalendar03,
                label: context.tr('calendar'),
                accent: AppColors.today,
                selected: _index == 1,
                onTap: () => _goTo(1),
              ),
              const SizedBox(width: 76),
              _NavItem(
                icon: HugeIcons.strokeRoundedAnalytics02,
                label: context.tr('insights'),
                accent: AppColors.ovulation,
                selected: _index == 2,
                onTap: () => _goTo(2),
              ),
              _NavItem(
                icon: HugeIcons.strokeRoundedSetting07,
                label: context.tr('settings'),
                accent: AppColors.mint,
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
        width: 58,
        height: 58,
        child: ClayButton(
          onTap: onTap,
          color: AppColors.primary,
          radius: 20,
          padding: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: const HugeIcon(icon: HugeIcons.strokeRoundedPlusSign,
              size: 30,
              color: Colors.white,
            )
          ),
        ),
      ),
    );
  }
}

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
    final dimColor = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.45);

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
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 46,
                height: 28,
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusCircular),
                ),
                child: HugeIcon(
                  icon: icon,
                  size: 20,
                  color: selected ? accent : dimColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? accent : dimColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
