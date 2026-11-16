import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';

import '../../screens/home/widgets/widget_calendar_render.dart';
import '../../screens/insights/widgets/widget_insights_render.dart';
import '../cycle/cycle_calculation_service.dart';
import '../localization/app_localizations.dart';
import '../localization/language_service.dart';
import '../storage/storage_service.dart';

/// Pushes the current cycle state to the Android home-screen widgets and keeps
/// them fresh.
///
/// The widget surfaces themselves are native (`RemoteViews`), so this service
/// is the bridge: it computes the same stats the app screens show, renders each
/// face to a PNG with [HomeWidget.renderFlutterWidget] so the widgets match the
/// app's design, stores the calendar's two button labels (pre-translated, as
/// `RemoteViews` cannot resolve Flutter strings) and then asks each Android
/// `AppWidgetProvider` to redraw. Two widgets are published:
///
/// * **Floii Calendar** — the month grid plus cycle stats.
/// * **Floii Insights** — the Insights tab's hero overview card.
class HomeWidgetService {
  static final HomeWidgetService _instance = HomeWidgetService._internal();
  factory HomeWidgetService() => _instance;
  HomeWidgetService._internal();

  /// Fully-qualified names of the Android `AppWidgetProvider`s.
  static const String androidCalendarProvider =
      'com.example.floiiiiiii.FloiiWidgetProvider';
  static const String androidInsightsProvider =
      'com.example.floiiiiiii.FloiiInsightsWidgetProvider';

  static const String _calendarImageKey = 'calendar_image';
  static const String _insightsImageKey = 'insights_image';
  static const String _logPeriodKey = 'log_period_label';
  static const String _logMoodKey = 'log_mood_label';

  /// Emits a widget-originated deep link (`floii://log-period` /
  /// `floii://log-mood`) for the shell to route once it is ready.
  final ValueNotifier<Uri?> pendingDeepLink = ValueNotifier<Uri?>(null);

  bool _initialized = false;
  Timer? _debounce;
  StreamSubscription<Uri?>? _clickSub;

  bool get _supported => !kIsWeb && Platform.isAndroid;

  /// Registers data-change listeners and performs an initial render.
  ///
  /// Safe to call more than once; the first call wins.
  Future<void> init() async {
    if (!_supported || _initialized) return;
    _initialized = true;

    for (final name in <String>[
      StorageKeys.dailyData,
      StorageKeys.settings,
      StorageKeys.options,
    ]) {
      if (Hive.isBoxOpen(name)) {
        Hive.box(name).listenable().addListener(_scheduleUpdate); 
      }
    }

    await update();
  }

  /// Listens for taps on the widget and captures an initial deep link when the
  /// app was cold-started from one of the widget buttons.
  Future<void> handleLaunch() async {
    if (!_supported) return;
    try {
      final initial = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initial != null) _emit(initial);

      await _clickSub?.cancel();
      _clickSub = HomeWidget.widgetClicked.listen((uri) {
        if (uri != null) _emit(uri);
      });
    } catch (e) {
      debugPrint('[Floii] Home widget launch handling failed: $e');
    }
  }

  void _emit(Uri uri) {
    if (uri.scheme != 'floii') return;
    pendingDeepLink.value = uri;
  }

  void _scheduleUpdate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      update();
    });
  }

  /// Recomputes the cycle state, re-renders the calendar image and refreshes
  /// the widget. Never throws: a widget failure must not affect the app.
  Future<void> update() async {
    if (!_supported) return;
    try {
      final storage = StorageService();
      final loc = AppLocalizations(LanguageService().currentLocale);
      final isDark = storage.getDarkMode();
      final now = DateTime.now();

      final stats = CycleCalculationService.calculateStats(
        storage.getAllDailyData(),
        defaultCycleLength: storage.getCycleLength(),
        defaultPeriodLength: storage.getMenstrualDays(),
      );

      await HomeWidget.saveWidgetData<String>(
        _logPeriodKey,
        loc.translate('trackMyPeriod'),
      );
      await HomeWidget.saveWidgetData<String>(
        _logMoodKey,
        loc.translate('addMood'),
      );

      final periodKeys = storage
          .getPeriodDays()
          .map((d) => storage.keyForDate(d.date))
          .toSet();

      await HomeWidget.renderFlutterWidget(
        buildHomeWidgetFace(
          loc: loc,
          isDark: isDark,
          today: now,
          stats: stats,
          periodKeys: periodKeys,
          predictedPeriods: _predictedPeriods(storage, stats),
        ),
        key: _calendarImageKey,
        logicalSize: kHomeWidgetLogicalSize,
      );
      await HomeWidget.renderFlutterWidget(
        buildInsightsWidgetFace(
          loc: loc,
          isDark: isDark,
          today: now,
          stats: stats,
        ),
        key: _insightsImageKey,
        logicalSize: kInsightsWidgetLogicalSize,
      );

      await HomeWidget.updateWidget(
        qualifiedAndroidName: androidCalendarProvider,
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: androidInsightsProvider,
      );
    } catch (e) {
      debugPrint('[Floii] Home widget update failed: $e');
    }
  }

  /// The next three predicted period windows, mirroring the home screen so the
  /// widget highlights the same upcoming dates.
  List<DateTime> _predictedPeriods(
    StorageService storage,
    Map<String, dynamic> stats,
  ) {
    final periods = stats['periods'] as List<List<DateTime>>? ?? [];
    if (periods.isEmpty) return [];

    final average = stats['average'] as int? ?? 28;
    final menstrualDays = storage.getMenstrualDays();
    final dates = <DateTime>[];

    var lastStart = periods.last.first;
    for (var i = 0; i < 3; i++) {
      lastStart = lastStart.add(Duration(days: average));
      for (var d = 0; d < menstrualDays; d++) {
        dates.add(DateTime(lastStart.year, lastStart.month, lastStart.day + d));
      }
    }
    return dates;
  }
}
