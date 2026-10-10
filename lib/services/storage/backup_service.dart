import 'dart:convert';

import '../../models/cycle_models.dart';
import 'storage_service.dart';

/// Builds and consumes the Floii JSON backup file:
/// `{ app, version, exportedAt, menstrualDays, cycleLength, dailyData: [...] }`.
///
/// File I/O itself is handled by `file_picker` (save/pick), so this service
/// stays platform-agnostic and works on mobile, desktop and web.
class BackupService {
  static const String _appMarker = 'floi-backup';
  static const int _backupVersion = 1;

  final StorageService _storage = StorageService();

  /// Serializes all tracked days plus the period-length setting to JSON.
  String buildBackup() {
    final entries = _storage.getAllDailyData();

    return jsonEncode({
      'app': _appMarker,
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'menstrualDays': _storage.getMenstrualDays(),
      'cycleLength': _storage.getCycleLength(),
      'dailyData': entries.map((d) {
        return {
          'date': d.date.toIso8601String(),
          'isPeriod': d.isPeriod,
          'mood': d.mood,
        };
      }).toList(),
    });
  }

  /// Validates and restores a backup, replacing the current data.
  /// Returns the number of restored daily entries.
  /// Throws [FormatException] if the payload is not a valid Floii backup.
  Future<int> importBackup(String jsonStr) async {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map) {
      throw const FormatException('Backup root must be a JSON object');
    }
    if (decoded['app'] != _appMarker) {
      throw const FormatException('Missing Floii backup marker');
    }
    final raw = decoded['dailyData'];
    if (raw is! List) {
      throw const FormatException('Backup has no dailyData array');
    }

    final restored = raw.whereType<Map>().map((e) {
      final date = DateTime.tryParse('${e['date']}');
      if (date == null) {
        throw const FormatException('Backup contains an invalid date');
      }
      return DailyData(
        date: date,
        isPeriod: e['isPeriod'] == true,
        mood: e['mood'] as String?,
      );
    }).toList();

    final menstrualDays = (decoded['menstrualDays'] as num?)?.toInt();
    final cycleLength = (decoded['cycleLength'] as num?)?.toInt();

    // Payload is valid; wipe current data, then restore.
    await _storage.clearAllData();

    final box = _storage.dailyDataBox;
    for (final data in restored) {
      await box.put(_storage.keyForDate(data.date), data);
    }

    if (menstrualDays != null && menstrualDays > 0) {
      await _storage.setMenstrualDays(menstrualDays);
    }

    if (cycleLength != null && cycleLength >= 21 && cycleLength <= 40) {
      await _storage.setCycleLength(cycleLength);
    }

    return restored.length;
  }
}
