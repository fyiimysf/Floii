import '../../models/cycle_models.dart';
import '../../utils/extensions/date_extensions.dart';
import '../storage/storage_service.dart';

/// Central entry point for changing which days are marked as period days.
/// Used by the home calendar and by the center "Add cycle" FAB so both flows
/// write through the same code path.
class PeriodLogService {
  final StorageService _storage;

  PeriodLogService({StorageService? storage})
      : _storage = storage ?? StorageService();

  /// Marks [startDate] for [duration] consecutive days as period days.
  void markRange(DateTime startDate, int duration) {
    for (int i = 0; i < duration; i++) {
      final date = startDate.addDays(i);
      final data = _storage.getDailyData(date) ?? DailyData(date: date);
      data.isPeriod = true;
      _storage.saveDailyData(date, data);
    }
  }

  /// Clears up to 7 days of period flags starting at [startDate].
  void clearRange(DateTime startDate) {
    for (int i = 0; i < 7; i++) {
      final date = startDate.addDays(i);
      final data = _storage.getDailyData(date);
      if (data != null) {
        data.isPeriod = false;
        _storage.saveDailyData(date, data);
      }
    }
  }
}