import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../models/enums.dart';
import '../cycle/cycle_calculation_service.dart';
import '../cycle/phase_service.dart';
import '../localization/app_localizations.dart';
import '../localization/language_service.dart';
import '../storage/storage_service.dart';

/// Schedules the user-chosen reminders (period, mood logging, ovulation date
/// and phase change), localized per the active language.
///
/// Every reminder type has two independent delivery paths so a single OS
/// failure can't silently kill it:
///
/// 1. OS alarms (`AlarmManager`) armed via `zonedSchedule`, which deliver
///    even when the app is in the background or closed (requires the alarm
///    permission in the manifest).
/// 2. An in-app tick driven by the device clock (`DateTime.now()`), which
///    shows overdue reminders while the app is open even if the OS alarm is
///    suppressed by the device (vendor battery throttling, etc.).
///
/// Every reminder is gated on its own toggle, read fresh from storage each
/// time a reminder is armed or shown, and every rebuild of the OS alarms is
/// serialized (see [syncReminder]) so a toggle the user just flipped can never
/// be overwritten by a rebuild that was already under way.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int periodReminderBaseId = 2000;
  static const int periodReminderModulo = 45;
  static const int moodReminderBaseId = 2100;
  static const int moodReminderModulo = 40;
  static const int moodReminderLookaheadDays = 30;
  static const int ovulationReminderId = 2200;
  static const int phaseReminderBaseId = 2300;
  static const int phaseReminderModulo = 55;
  static const int phaseReminderLookaheadDays = 45;
  static const int testNotificationId = 1002;
  static const int testAlarmId = 1003;
  static const String reminderChannelId = 'period_reminders';
  static const String reminderChannelName = 'Cycle reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Timer? _foregroundTimer;
  bool _initialized = false;
  bool _realTimeZoneResolved = false;

  /// The in-flight [syncReminder] drain, or null when idle. Only one rebuild
  /// of the OS alarms may run at a time — see [syncReminder].
  Future<void>? _activeSync;

  /// Set whenever a sync is requested. A request that lands while a sync is
  /// running is not lost: the drain loops once more with fresh preferences.
  bool _syncRequested = false;

  /// `type -> dayKey` of the last reminder shown from the device-clock tick,
  /// so each reminder fires at most once per day while the app is open.
  final Map<String, String> _shownToday = <String, String>{};

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings:
          const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    if (kIsWeb) return;
    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      _realTimeZoneResolved = true;
      debugPrint('[Floii] Reminder timezone: ${tz.local.name}');
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
      debugPrint('[Floii] Timezone lookup failed ($e); '
          'will carry the schedule on the device-clock offset instead.');
    }

    _initialized = true;
    _foregroundTimer?.cancel();
    _foregroundTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _maybeShowAllFromDeviceClock(),
    );
  }

  /// Requests permission and (re)builds all scheduled reminders from the
  /// stored user preferences. Never throws: it cancels stale alarms first,
  /// then arms each enabled reminder, falling back to inexact delivery when
  /// exact alarms are unavailable.
  ///
  /// Rebuilds are serialized: [syncReminder] is called from app launch, from
  /// every resume and from every settings change, so overlapping calls are
  /// expected. Without serialization a rebuild that had already read
  /// `reminderEnabled == true` could finish *after* the user flipped the
  /// toggle off and re-arm alarms for a disabled reminder — the toggle would
  /// then look completely ignored. Here a request arriving mid-rebuild is
  /// coalesced and replayed with the current preferences, so the last change
  /// always wins.
  Future<void> syncReminder() {
    if (kIsWeb) return Future<void>.value();

    _syncRequested = true;
    _activeSync ??= _drainSyncs();
    return _activeSync!;
  }

  /// Runs sync passes until no further request arrived while the previous pass
  /// was running.
  Future<void> _drainSyncs() async {
    try {
      while (_syncRequested) {
        _syncRequested = false;
        try {
          await _syncOnce();
        } catch (e) {
          // A failed pass must never break the queue, otherwise the alarms
          // would be left in whatever state the failure produced.
          debugPrint('[Floii] Reminder sync failed: $e');
        }
      }
    } finally {
      _activeSync = null;
    }
  }

  /// A single cancel-then-arm pass. Always re-reads the preferences, so it
  /// reflects the toggles as they are at the moment the pass actually runs.
  Future<void> _syncOnce() async {
    final storage = StorageService();

    await _cancelAllReminders();

    final anyEnabled = storage.getReminderEnabled() ||
        storage.getMoodReminderEnabled() ||
        storage.getOvulationReminderEnabled() ||
        storage.getPhaseReminderEnabled();

    _dropDisabledTicks(storage);

    if (!anyEnabled) {
      debugPrint('[Floii] All reminders disabled; cleared scheduled alarms.');
      return;
    }

    await _requestPermissions();

    final stats = _computeStats();

    if (storage.getReminderEnabled()) {
      await _schedulePeriodWindow(storage, stats);
    }
    if (storage.getMoodReminderEnabled()) {
      await _scheduleMoodReminders(storage);
    }
    if (storage.getOvulationReminderEnabled()) {
      await _scheduleOvulation(storage, stats);
    }
    if (storage.getPhaseReminderEnabled()) {
      await _schedulePhaseChanges(storage, stats);
    }

    final pending = await _plugin.pendingNotificationRequests();
    debugPrint('[Floii] Pending notifications: ${pending.length}');
    for (final request in pending) {
      debugPrint('[Floii]   id=${request.id} title=${request.title} '
          'body=${request.body}');
    }
  }

  /// Clears the once-per-day tick bookkeeping of any reminder that is now
  /// switched off, so re-enabling it later the same day can fire again.
  void _dropDisabledTicks(StorageService storage) {
    if (!storage.getReminderEnabled()) _shownToday.remove('period');
    if (!storage.getMoodReminderEnabled()) _shownToday.remove('mood');
    if (!storage.getOvulationReminderEnabled()) {
      _shownToday.remove('ovulation');
    }
    if (!storage.getPhaseReminderEnabled()) _shownToday.remove('phase');
  }

  /// Cancels every armed OS alarm without rebuilding, so the device stops
  /// reminding even if the app is never launched again. Used by the factory
  /// reset, which wipes the preferences that `syncReminder` reads.
  Future<void> cancelAllReminders() async {
    await _cancelAllReminders();
    _shownToday.clear();
  }

  /// Instantly shows a one-off notification so the user can verify the
  /// reminder pipeline (permission, channel and icon) works on the device.
  Future<void> sendTestNotification() async {
    await _plugin.show(
      id: testNotificationId,
      title: 'Floii',
      body: _loc().translate('testNotificationBody'),
      notificationDetails: _details,
    );
  }

  /// Arms a real OS alarm roughly [secondsFromNow] from now. This proves the
  /// `AlarmManager` -> receiver path independently of the recurring reminder,
  /// which is the layer the test notification (`show`) does not cover.
  Future<void> scheduleTestAlarm({int secondsFromNow = 30}) async {
    final scheduledDate =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: secondsFromNow));
    await _plugin.zonedSchedule(
      id: testAlarmId,
      title: 'Floii (scheduled test)',
      body: _loc().translate('testNotificationBody'),
      scheduledDate: scheduledDate,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint('[Floii] Test alarm armed for '
        '${scheduledDate.toIso8601String()}');
  }

  Map<String, dynamic> _computeStats() {
    final storage = StorageService();
    return CycleCalculationService.calculateStats(
      storage.getAllDailyData(),
      defaultCycleLength: storage.getCycleLength(),
      defaultPeriodLength: storage.getMenstrualDays(),
    );
  }

  /// Arms one OS alarm per day of the period window (lead-in days before the
  /// predicted period start through the predicted period end), each with a
  /// message that reflects how close the user is to / how far into their
  /// period they are. Nothing is scheduled outside the window.
  Future<void> _schedulePeriodWindow(
      StorageService storage, Map<String, dynamic> stats) async {
    final prediction = stats['prediction'] as DateTime?;
    if (prediction == null) return;

    final averageCycleLength =
        stats['average'] as int? ?? storage.getCycleLength();
    final periodLength = (stats['averagePeriodLength'] as int?) ??
        (stats['currentPeriodLength'] as int?) ??
        storage.getMenstrualDays();
    final leadDays = storage.getPeriodLeadDays();
    final hour = storage.getReminderTime() ~/ 60;
    final minute = storage.getReminderTime() % 60;

    final window = computePeriodWindow(
      prediction: prediction,
      averageCycleLength: averageCycleLength,
      periodLength: periodLength,
      leadDays: leadDays,
      now: DateTime.now(),
    );
    if (window == null) return;

    final today = _startOfDay(DateTime.now());
    var day = window.windowStart.isBefore(today) ? today : window.windowStart;
    while (!day.isAfter(window.windowEnd)) {
      final fire = DateTime(day.year, day.month, day.day, hour, minute);
      if (fire.isAfter(DateTime.now())) {
        await _scheduleOneShot(
          id: _dayBasedId(day, periodReminderBaseId, periodReminderModulo),
          fireAt: fire,
          title: 'Floii',
          body: _periodMessageFor(day, window.predictedStart),
        );
      }
      day = day.add(const Duration(days: 1));
    }

    debugPrint('[Floii] Period window armed: '
        'start=${window.windowStart.toIso8601String()} '
        'end=${window.windowEnd.toIso8601String()} '
        '(${window.windowEnd.difference(window.windowStart).inDays + 1} days, '
        'lead=$leadDays, '
        '${window.predictedStart.toIso8601String()} projected).');
  }

  /// One-shot alarm for the next predicted ovulation date that is still in
  /// the future (stepping forward a cycle if the current one has passed).
  Future<void> _scheduleOvulation(
      StorageService storage, Map<String, dynamic> stats) async {
    final ovulationDate = stats['ovulationDate'] as DateTime?;
    if (ovulationDate == null) return;

    final averageCycle = stats['average'] as int? ?? storage.getCycleLength();
    final hour = storage.getOvulationReminderTime() ~/ 60;
    final minute = storage.getOvulationReminderTime() % 60;
    final now = DateTime.now();

    var target = _startOfDay(ovulationDate);
    while (true) {
      final fire =
          DateTime(target.year, target.month, target.day, hour, minute);
      if (fire.isAfter(now)) break;
      target = target.add(Duration(days: averageCycle));
    }

    final fire = DateTime(target.year, target.month, target.day, hour, minute);
    await _scheduleOneShot(
      id: ovulationReminderId,
      fireAt: fire,
      title: 'Floii',
      body: _ovulationReminderBody(target),
    );
    debugPrint('[Floii] Ovulation reminder armed for '
        '${fire.toIso8601String()}.');
  }

  /// One-shot alarm for each phase-change day in the next
  /// [phaseReminderLookaheadDays] days (bounded, so at most one alarm per
  /// day), each carrying the name of the phase being entered.
  Future<void> _schedulePhaseChanges(
      StorageService storage, Map<String, dynamic> stats) async {
    final today = _startOfDay(DateTime.now());
    final hour = storage.getPhaseReminderTime() ~/ 60;
    final minute = storage.getPhaseReminderTime() % 60;

    CyclePhase? previousPhase;
    var changeCount = 0;
    for (var i = 0; i <= phaseReminderLookaheadDays; i++) {
      final day = today.add(Duration(days: i));
      final phase = PhaseService.getPhase(day, stats);
      if (previousPhase != null && phase != previousPhase) {
        final fire = DateTime(day.year, day.month, day.day, hour, minute);
        if (fire.isAfter(DateTime.now())) {
          await _scheduleOneShot(
            id: _dayBasedId(day, phaseReminderBaseId, phaseReminderModulo),
            fireAt: fire,
            title: 'Floii',
            body: _phaseChangedBody(day, phase),
          );
          changeCount++;
        }
      }
      previousPhase = phase;
    }

    if (changeCount > 0) {
      debugPrint('[Floii] Phase-change reminders armed ($changeCount events).');
    }
  }

  /// Arms one OS alarm per day for the next [moodReminderLookaheadDays] days,
  /// each carrying a randomly selected mood prompt, so the notification is
  /// never identical twice (a single repeating alarm would repeat the same
  /// baked body every day).
  Future<void> _scheduleMoodReminders(StorageService storage) async {
    final today = _startOfDay(DateTime.now());
    final hour = storage.getMoodReminderTime() ~/ 60;
    final minute = storage.getMoodReminderTime() % 60;

    for (var i = 0; i < moodReminderLookaheadDays; i++) {
      final day = today.add(Duration(days: i));
      final fire = DateTime(day.year, day.month, day.day, hour, minute);
      if (fire.isAfter(DateTime.now())) {
        await _scheduleOneShot(
          id: _dayBasedId(day, moodReminderBaseId, moodReminderModulo),
          fireAt: fire,
          title: 'Floii',
          body: _moodBody(day),
        );
      }
    }

    debugPrint('[Floii] Mood reminders armed for the next '
        '$moodReminderLookaheadDays days.');
  }

  Future<void> _scheduleOneShot({
    required int id,
    required DateTime fireAt,
    required String title,
    required String body,
  }) async {
    final scheduledAt = _realTimeZoneResolved
        ? tz.TZDateTime(tz.local, fireAt.year, fireAt.month, fireAt.day,
            fireAt.hour, fireAt.minute)
        : _toUtcCarrier(fireAt);

    Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledAt,
          notificationDetails: _details,
          androidScheduleMode: mode,
        );

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
      debugPrint('[Floii] Armed id=$id for ${fireAt.toIso8601String()} '
          '($title — $body).');
    } catch (e1) {
      try {
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
        debugPrint('[Floii] Armed id=$id (inexact) for '
            '${fireAt.toIso8601String()}.');
      } catch (e2) {
        debugPrint('[Floii] FAILED to arm id=$id (exact: $e1; '
            'inexact: $e2).');
      }
    }
  }

  /// Asks for the notification and exact-alarm permissions.
  ///
  /// Each request is isolated: a platform that refuses (or has no
  /// implementation for) one of them must not stop the remaining permission
  /// from being asked for, nor abort the scheduling that follows.
  Future<void> _requestPermissions() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('[Floii] Notification permission request failed: $e');
    }
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('[Floii] Exact alarm permission request failed: $e');
    }
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('[Floii] iOS permission request failed: $e');
    }
  }

  /// Disarms every pending OS alarm in one call.
  ///
  /// The previous implementation swept the id ranges one id at a time
  /// (~1,150 `cancel` calls, each a platform-channel round trip). That is slow
  /// enough to keep a rebuild "in flight" for many seconds, which is what let
  /// a stale rebuild re-arm alarms after the user had already turned a
  /// reminder off. It was also fragile: a single failed `cancel` aborted the
  /// loop, leaving every later id armed. A bulk cancel is both atomic and
  /// immune to ids armed by older builds, and it also clears the one-off test
  /// helpers that used to be deliberately spared.
  Future<void> _cancelAllReminders() async {
    await _plugin.cancelAllPendingNotifications();
  }

  /// Reminders shown directly from the device clock while the app is running,
  /// so they fire even if the OS alarm is suppressed.
  void _maybeShowAllFromDeviceClock() {
    if (!_initialized || kIsWeb) return;

    final storage = StorageService();
    final stats = _computeStats();

    unawaited(_maybeShowPeriodFromDeviceClock(storage, stats));
    unawaited(_maybeShowMoodFromDeviceClock(storage));
    unawaited(_maybeShowOvulationFromDeviceClock(storage, stats));
    unawaited(_maybeShowPhaseFromDeviceClock(storage, stats));
  }

  /// Posts [body] under [id], first disarming the OS alarm that shares the id.
  ///
  /// The alarm and the in-app tick both use the same per-day id, but posting
  /// alone does not deduplicate them: without this the reminder time arrives,
  /// the alarm posts its copy and the tick posts another one a few seconds
  /// later. Cancelling first collapses both deliveries into a single
  /// notification, and it also stops a throttled alarm from firing again
  /// later in the day after the tick already covered it.
  Future<void> _showFromDeviceClock({
    required int id,
    required String body,
  }) async {
    await _plugin.cancel(id: id);
    await _plugin.show(
      id: id,
      title: 'Floii',
      body: body,
      notificationDetails: _details,
      payload: 'in-app-tick',
    );
  }

  Future<void> _maybeShowPeriodFromDeviceClock(
      StorageService storage, Map<String, dynamic> stats) async {
    if (!storage.getReminderEnabled()) return;
    if (!_nowAtOrPast(storage.getReminderTime())) return;

    final now = DateTime.now();
    final today = _startOfDay(now);
    final prediction = stats['prediction'] as DateTime?;
    if (prediction == null) return;

    final window = computePeriodWindow(
      prediction: prediction,
      averageCycleLength: stats['average'] as int? ?? storage.getCycleLength(),
      periodLength: (stats['averagePeriodLength'] as int?) ??
          (stats['currentPeriodLength'] as int?) ??
          storage.getMenstrualDays(),
      leadDays: storage.getPeriodLeadDays(),
      now: now,
    );
    if (window == null) return;

    if (today.isBefore(window.windowStart) || today.isAfter(window.windowEnd)) {
      return;
    }
    if (!_markShown('period')) return;

    await _showFromDeviceClock(
      id: _dayBasedId(today, periodReminderBaseId, periodReminderModulo),
      body: _periodMessageFor(now, window.predictedStart),
    );
    debugPrint('[Floii] Period reminder shown from in-app device-clock tick.');
  }

  Future<void> _maybeShowMoodFromDeviceClock(StorageService storage) async {
    if (!storage.getMoodReminderEnabled()) return;
    if (!_nowAtOrPast(storage.getMoodReminderTime())) return;
    if (!_markShown('mood')) return;

    final today = _startOfDay(DateTime.now());
    await _showFromDeviceClock(
      id: _dayBasedId(today, moodReminderBaseId, moodReminderModulo),
      body: _moodBody(today),
    );
    debugPrint('[Floii] Mood reminder shown from in-app device-clock tick.');
  }

  Future<void> _maybeShowOvulationFromDeviceClock(
      StorageService storage, Map<String, dynamic> stats) async {
    if (!storage.getOvulationReminderEnabled()) return;
    if (!_nowAtOrPast(storage.getOvulationReminderTime())) return;

    final ovulationDate = stats['ovulationDate'] as DateTime?;
    if (ovulationDate == null) return;

    final today = _startOfDay(DateTime.now());
    if (_startOfDay(ovulationDate).difference(today).inDays != 0) return;
    if (!_markShown('ovulation')) return;

    await _showFromDeviceClock(
      id: ovulationReminderId,
      body: _ovulationReminderBody(_startOfDay(ovulationDate)),
    );
    debugPrint(
        '[Floii] Ovulation reminder shown from in-app device-clock tick.');
  }

  Future<void> _maybeShowPhaseFromDeviceClock(
      StorageService storage, Map<String, dynamic> stats) async {
    if (!storage.getPhaseReminderEnabled()) return;
    if (!_nowAtOrPast(storage.getPhaseReminderTime())) return;

    final today = _startOfDay(DateTime.now());
    final phaseToday = PhaseService.getPhase(today, stats);
    final phaseYesterday =
        PhaseService.getPhase(today.subtract(const Duration(days: 1)), stats);
    if (phaseToday == phaseYesterday) return;
    if (!_markShown('phase')) return;

    await _showFromDeviceClock(
      id: _dayBasedId(today, phaseReminderBaseId, phaseReminderModulo),
      body: _phaseChangedBody(today, phaseToday),
    );
    debugPrint('[Floii] Phase-change reminder shown from in-app '
        'device-clock tick.');
  }

  bool _nowAtOrPast(int targetMinutes) {
    final now = DateTime.now();
    return now.hour * 60 + now.minute >= targetMinutes;
  }

  bool _markShown(String type) {
    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';
    if (_shownToday[type] == dayKey) return false;
    _shownToday[type] = dayKey;
    return true;
  }

  String _periodMessageFor(DateTime day, DateTime prediction) {
    final daysUntil =
        _startOfDay(prediction).difference(_startOfDay(day)).inDays;
    final seed = _dayKey(day);
    if (daysUntil > 0) {
      if (daysUntil == 1) {
        return _pick([
          'periodMayStartTomorrow',
          'periodMayStartTomorrow_1',
          'periodMayStartTomorrow_2'
        ], seed);
      }
      return _pick(
          [
            'periodMayStartInDays',
            'periodMayStartInDays_1',
            'periodMayStartInDays_2',
            'periodMayStartInDays_3'
          ],
          seed,
          args: {'days': daysUntil});
    }
    if (daysUntil == 0) {
      return _pick([
        'periodMayStartToday',
        'periodMayStartToday_1',
        'periodMayStartToday_2'
      ], seed);
    }
    return _pick(['periodDayN', 'periodDayN_1', 'periodDayN_2'], seed,
        args: {'day': -daysUntil + 1});
  }

  String _moodBody(DateTime day) {
    return _pick([
      'moodReminderBody',
      'moodReminderBody_1',
      'moodReminderBody_2',
      'moodReminderBody_3'
    ], _dayKey(day));
  }

  String _ovulationReminderBody(DateTime target) {
    return _pick(
        [
          'ovulationReminderBody',
          'ovulationReminderBody_1',
          'ovulationReminderBody_2'
        ],
        _dayKey(target),
        args: {'date': DateFormat('yyyy-MM-dd').format(target)});
  }

  String _phaseChangedBody(DateTime day, CyclePhase phase) {
    return _pick(['phaseChangedTo', 'phaseChangedTo_1', 'phaseChangedTo_2'],
        _dayKey(day),
        args: {'phase': phase.name});
  }

  /// Deterministically picks one of [keys] using [seed], so the same day
  /// always yields the same variant (the in-app tick and the OS alarm for a
  /// given day agree), while different days get variety.
  String _pick(List<String> keys, String seed, {Map<String, dynamic>? args}) {
    final key = keys[(seed.hashCode & 0x7fffffff) % keys.length];
    final loc = _loc();
    return args != null ? loc.translateWithArgs(key, args) : loc.translate(key);
  }

  String _dayKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  /// Stable per-date id inside [base .. base+modulo-1], so OS alarms and the
  /// in-app tick map the same calendar day onto the same notification id
  /// (deduplicating double delivery) regardless of when they were armed.
  int _dayBasedId(DateTime day, int base, int modulo) {
    final daysEpoch = _startOfDay(day).difference(DateTime(2020, 1, 1)).inDays;
    return base + (daysEpoch % modulo);
  }

  /// Computes the period reminder window around the next predicted period
  /// start. The window spans [leadDays] before the predicted start through
  /// [periodLength] days of predicted period.
  ///
  /// When the prediction is stale (its window already ended), it is advanced
  /// forward by whole [averageCycleLength] cycles until the window reaches the
  /// present/future — so reminders keep flowing even if tracking stops, in
  /// step with the phase reminders. Returns null when there is no prediction.
  static ({DateTime predictedStart, DateTime windowStart, DateTime windowEnd})?
      computePeriodWindow({
    required DateTime prediction,
    required int averageCycleLength,
    required int periodLength,
    required int leadDays,
    required DateTime now,
  }) {
    if (averageCycleLength < 1 || periodLength < 1 || leadDays < 0) {
      return null;
    }

    DateTime toDayStart(DateTime date) =>
        DateTime(date.year, date.month, date.day);

    final today = toDayStart(now);
    var predictedStart = toDayStart(prediction);

    while (
        predictedStart.add(Duration(days: periodLength - 1)).isBefore(today)) {
      predictedStart = predictedStart.add(Duration(days: averageCycleLength));
    }

    return (
      predictedStart: predictedStart,
      windowStart: predictedStart.subtract(Duration(days: leadDays)),
      windowEnd: predictedStart.add(Duration(days: periodLength - 1)),
    );
  }

  AppLocalizations _loc() => AppLocalizations(LanguageService().currentLocale);

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static tz.TZDateTime _toUtcCarrier(DateTime local) {
    final utc = local.toUtc();
    return tz.TZDateTime(
        tz.UTC, utc.year, utc.month, utc.day, utc.hour, utc.minute, utc.second);
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      reminderChannelId,
      reminderChannelName,
      channelDescription:
          'Reminders for your period, mood, ovulation and cycle phases',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );
}
