import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:floi/models/cycle_models.dart';
import 'package:floi/models/enums.dart';
import 'package:floi/services/storage/storage_service.dart';

void main() {
  bool adaptersRegistered = false;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('storage_service_test');
    Hive.init(dir.path);
    if (!adaptersRegistered) {
      Hive.registerAdapter(DailyDataAdapter());
      Hive.registerAdapter(OptionsAdapter());
      adaptersRegistered = true;
    }
    await Hive.openBox<int>('settings');
    await Hive.openBox<Options>('options');
    await Hive.openBox<DailyData>('dailyData');
  });

  tearDown(() async {
    await Hive.close();
  });

  group('cycle length', () {
    test('defaults to 28 when unset', () {
      expect(StorageService().getCycleLength(), 28);
    });

    test('round-trips a custom cycle length', () async {
      await StorageService().setCycleLength(32);
      expect(StorageService().getCycleLength(), 32);
    });
  });

  group('reminder settings', () {
    test('defaults to enabled and 08:00', () {
      expect(StorageService().getReminderEnabled(), isTrue);
      expect(StorageService().getReminderTime(), 8 * 60);
    });

    test('round-trips disabled state and custom time', () async {
      await StorageService().setReminderEnabled(false);
      await StorageService().setReminderTime(21 * 60 + 30);
      expect(StorageService().getReminderEnabled(), isFalse);
      expect(StorageService().getReminderTime(), 21 * 60 + 30);
    });
  });

  group('notification type settings', () {
    test('defaults for mood/ovulation/phase are off, lead days 3', () {
      expect(StorageService().getMoodReminderEnabled(), isFalse);
      expect(StorageService().getMoodReminderTime(), 9 * 60);
      expect(StorageService().getOvulationReminderEnabled(), isFalse);
      expect(StorageService().getOvulationReminderTime(), 8 * 60);
      expect(StorageService().getPhaseReminderEnabled(), isFalse);
      expect(StorageService().getPhaseReminderTime(), 8 * 60);
      expect(StorageService().getPeriodLeadDays(), 3);
    });

    test('round-trips each toggle and time', () async {
      await StorageService().setMoodReminderEnabled(true);
      await StorageService().setMoodReminderTime(12 * 60);
      await StorageService().setOvulationReminderEnabled(true);
      await StorageService().setOvulationReminderTime(7 * 60);
      await StorageService().setPhaseReminderEnabled(true);
      await StorageService().setPhaseReminderTime(18 * 60);
      await StorageService().setPeriodLeadDays(5);

      expect(StorageService().getMoodReminderEnabled(), isTrue);
      expect(StorageService().getMoodReminderTime(), 12 * 60);
      expect(StorageService().getOvulationReminderEnabled(), isTrue);
      expect(StorageService().getOvulationReminderTime(), 7 * 60);
      expect(StorageService().getPhaseReminderEnabled(), isTrue);
      expect(StorageService().getPhaseReminderTime(), 18 * 60);
      expect(StorageService().getPeriodLeadDays(), 5);
    });
  });

  group('mood logging', () {
    test('returns null when no mood logged', () {
      final date = DateTime(2026, 3, 5);
      expect(StorageService().getMoodForDate(date), isNull);
    });

    test('round-trips a mood for a date', () async {
      final date = DateTime(2026, 3, 5);
      await StorageService().setMoodForDate(date, Mood.energetic);
      expect(StorageService().getMoodForDate(date), Mood.energetic);
      expect(
        StorageService().getDailyData(date)?.isPeriod,
        isFalse,
      );
    });

    test('updating an existing daily entry keeps period flag', () async {
      final date = DateTime(2026, 3, 5);
      await StorageService().saveDailyData(
        date,
        DailyData(date: date, isPeriod: true),
      );
      await StorageService().setMoodForDate(date, Mood.sad);

      final data = StorageService().getDailyData(date);
      expect(data?.isPeriod, isTrue);
      expect(data?.mood, Mood.sad.emoji);
    });
  });

  group('daily data access', () {
    test('getAllDailyData exposes saved entries', () async {
      final date = DateTime(2026, 4, 1);
      await StorageService()
          .saveDailyData(date, DailyData(date: date, isPeriod: true));
      expect(StorageService().getAllDailyData(), hasLength(1));
      expect(StorageService().getPeriodDays(), hasLength(1));
    });
  });
}
