import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:floi/models/cycle_models.dart';
import 'package:floi/models/enums.dart';
import 'package:floi/services/storage/backup_service.dart';
import 'package:floi/services/storage/storage_service.dart';

void main() {
  bool adaptersRegistered = false;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('backup_service_test');
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

  group('BackupService', () {
    test('export/import round-trips data and settings', () async {
      final storage = StorageService();
      await storage.setMenstrualDays(5);
      await storage.setCycleLength(31);

      final date = DateTime(2026, 3, 5);
      await storage.saveDailyData(
        date,
        DailyData(date: date, isPeriod: true, mood: Mood.happy.emoji),
      );

      final json = BackupService().buildBackup();
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['menstrualDays'], 5);
      expect(decoded['cycleLength'], 31);

      // Wipe everything, then restore from the backup string.
      await storage.clearAllData();
      await storage.setMenstrualDays(7);

      final count = await BackupService().importBackup(json);
      expect(count, 1);

      final restored = storage.getDailyData(date);
      expect(restored, isNotNull);
      expect(restored!.isPeriod, isTrue);
      expect(restored.mood, Mood.happy.emoji);
      expect(storage.getMenstrualDays(), 5);
      expect(storage.getCycleLength(), 31);
    });

    test('rejects payloads without the Floii marker', () async {
      expect(
        () => BackupService().importBackup('{"app":"other","dailyData":[]}'),
        throwsFormatException,
      );
    });

    test('rejects invalid dates inside dailyData', () async {
      expect(
        () => BackupService().importBackup(
          '{"app":"floi-backup",'
          '"dailyData":[{"date":"not-a-date","isPeriod":true}]}',
        ),
        throwsFormatException,
      );
    });
  });
}
