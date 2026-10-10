import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:floi/models/cycle_models.dart';
import 'package:floi/services/localization/language_service.dart';
import 'package:floi/services/notifications/notification_service.dart';
import 'package:floi/services/storage/storage_service.dart';

/// Stands in for the OS notification store so tests can observe exactly which
/// alarms would be armed on the device. Mirrors the real semantics: a bulk
/// cancel drops every pending alarm, while `zonedSchedule` adds one.
class _FakeNotificationPlatform extends AndroidFlutterLocalNotificationsPlugin {
  final Map<int, String> pending = <int, String>{};
  final List<int> cancelledIds = <int>[];
  int bulkCancels = 0;

  /// Artificial latency per armed alarm, used to widen the window in which a
  /// rebuild is in flight.
  Duration armLatency = Duration.zero;

  @override
  Future<void> cancelAllPendingNotifications() async {
    bulkCancels++;
    pending.clear();
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelledIds.add(id);
    pending.remove(id);
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    AndroidNotificationDetails? notificationDetails,
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exact,
  }) async {
    if (armLatency > Duration.zero) await Future<void>.delayed(armLatency);
    pending[id] = body ?? '';
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    AndroidNotificationDetails? notificationDetails,
    String? payload,
  }) async {
    pending.remove(id);
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return pending.entries
        .map<PendingNotificationRequest>(
            (e) => PendingNotificationRequest(e.key, 'Floii', e.value, null))
        .toList();
  }

  List<int> get pendingPeriodIds => pending.keys
      .where((id) =>
          id >= NotificationService.periodReminderBaseId &&
          id <
              NotificationService.periodReminderBaseId +
                  NotificationService.periodReminderModulo)
      .toList()
    ..sort();
}

void main() {
  late _FakeNotificationPlatform platform;
  bool adaptersRegistered = false;

  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('notification_sync_test');
    Hive.init(dir.path);
    if (!adaptersRegistered) {
      Hive.registerAdapter(DailyDataAdapter());
      Hive.registerAdapter(OptionsAdapter());
      adaptersRegistered = true;
    }
    await Hive.openBox<int>('settings');
    await Hive.openBox<Options>('options');
    await Hive.openBox<DailyData>('dailyData');
    await LanguageService().init();

    platform = _FakeNotificationPlatform();
    FlutterLocalNotificationsPlatform.instance = platform;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    // Two logged periods, with the most recent one still in progress, so the
    // next predicted period (and therefore the reminder window) lands in the
    // future regardless of the time of day the test runs.
    final today = DateTime.now();
    for (final start in [35, 4]) {
      for (var i = 0; i < 5; i++) {
        final day = today.subtract(Duration(days: start + i));
        await StorageService()
            .saveDailyData(day, DailyData(date: day, isPeriod: true));
      }
    }
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    FlutterLocalNotificationsPlatform.instance = _FakeNotificationPlatform();
    await Hive.close();
  });

  test('arms the period reminder while its toggle is on', () async {
    await StorageService().setReminderEnabled(true);

    await NotificationService().syncReminder();

    expect(platform.pendingPeriodIds, isNotEmpty);
  });

  test('arms nothing when every toggle is off', () async {
    final storage = StorageService();
    await storage.setReminderEnabled(false);
    await storage.setMoodReminderEnabled(false);
    await storage.setOvulationReminderEnabled(false);
    await storage.setPhaseReminderEnabled(false);

    await NotificationService().syncReminder();

    expect(platform.pending, isEmpty);
  });

  test('a rebuild racing a toggle-off never leaves alarms armed', () async {
    final storage = StorageService();
    await storage.setReminderEnabled(true);
    // Make arming slow, so the in-flight rebuild is still running when the
    // user flips the toggle off.
    platform.armLatency = const Duration(milliseconds: 40);

    final inFlight = NotificationService().syncReminder();
    await Future<void>.delayed(const Duration(milliseconds: 5));

    await storage.setReminderEnabled(false);
    final afterToggle = NotificationService().syncReminder();

    await Future.wait([inFlight, afterToggle]);

    expect(platform.pending, isEmpty,
        reason: 'the toggle-off must win over the rebuild already running');
  });

  test('concurrent sync requests all settle on the latest preferences',
      () async {
    final storage = StorageService();
    await storage.setReminderEnabled(true);
    platform.armLatency = const Duration(milliseconds: 10);

    final first = NotificationService().syncReminder();
    final second = NotificationService().syncReminder();
    final third = NotificationService().syncReminder();
    await Future.wait([first, second, third]);

    expect(platform.pendingPeriodIds, isNotEmpty);
    expect(platform.bulkCancels, greaterThanOrEqualTo(1));
  });
}
