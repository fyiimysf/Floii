import 'package:hive_flutter/hive_flutter.dart';
import '../../models/cycle_models.dart';
import '../../models/enums.dart';

class StorageKeys {
  static const String settings = 'settings';
  static const String options = 'options';
  static const String dailyData = 'dailyData';
  static const String menstrualDays = 'menstrualDays';
  static const String cycleLength = 'cycleLength';
  static const String reminderEnabled = 'reminderEnabled';
  static const String reminderTime = 'reminderTime';
  static const String moodReminderEnabled = 'moodReminderEnabled';
  static const String moodReminderTime = 'moodReminderTime';
  static const String ovulationReminderEnabled = 'ovulationReminderEnabled';
  static const String ovulationReminderTime = 'ovulationReminderTime';
  static const String phaseReminderEnabled = 'phaseReminderEnabled';
  static const String phaseReminderTime = 'phaseReminderTime';
  static const String periodLeadDays = 'periodLeadDays';
  static const String darkMode = 'darkMode';
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Box<DailyData> get dailyDataBox {
    if (!Hive.isBoxOpen(StorageKeys.dailyData)) {
      throw StateError(
          'dailyData box not opened. Ensure Hive.openBox<DailyData>("${StorageKeys.dailyData}") is called in main.dart');
    }
    return Hive.box<DailyData>(StorageKeys.dailyData);
  }

  Box<int> get settingsBox {
    if (!Hive.isBoxOpen(StorageKeys.settings)) {
      throw StateError(
          'settings box not opened. Ensure Hive.openBox<int>("${StorageKeys.settings}") is called in main.dart');
    }
    return Hive.box<int>(StorageKeys.settings);
  }

  Box<Options> get optionsBox {
    if (!Hive.isBoxOpen(StorageKeys.options)) {
      throw StateError(
          'options box not opened. Ensure Hive.openBox<Options>("${StorageKeys.options}") is called in main.dart');
    }
    return Hive.box<Options>(StorageKeys.options);
  }

  Future<void> saveDailyData(DateTime date, DailyData data) async {
    final key = _dateToKey(date);
    await dailyDataBox.put(key, data);
  }

  DailyData? getDailyData(DateTime date) {
    final key = _dateToKey(date);
    return dailyDataBox.get(key);
  }

  List<DailyData> getAllDailyData() {
    if (!Hive.isBoxOpen(StorageKeys.dailyData)) return [];
    return dailyDataBox.values.toList();
  }

  List<DailyData> getPeriodDays() {
    return dailyDataBox.values.where((d) => d.isPeriod).toList();
  }

  Mood? getMoodForDate(DateTime date) {
    final mood = getDailyData(date)?.mood;
    if (mood == null) return null;
    return Mood.fromEmoji(mood);
  }

  Future<void> setMoodForDate(DateTime date, Mood mood) async {
    final existing = getDailyData(date);
    await dailyDataBox.put(
      keyForDate(date),
      existing ??
          DailyData(
            date: DateTime(date.year, date.month, date.day),
          ),
    );
    final saved = getDailyData(date);
    if (saved != null) {
      saved.mood = mood.emoji;
      await saved.save();
    }
  }

  int getMenstrualDays({int defaultValue = 7}) {
    return settingsBox.get(StorageKeys.menstrualDays,
            defaultValue: defaultValue) ??
        defaultValue;
  }

  Future<void> setMenstrualDays(int days) async {
    await settingsBox.put(StorageKeys.menstrualDays, days);
  }

  int getCycleLength({int defaultValue = 28}) {
    return settingsBox.get(StorageKeys.cycleLength,
            defaultValue: defaultValue) ??
        defaultValue;
  }

  Future<void> setCycleLength(int days) async {
    await settingsBox.put(StorageKeys.cycleLength, days);
  }

  bool getReminderEnabled({bool defaultValue = true}) {
    final stored = settingsBox.get(StorageKeys.reminderEnabled);
    if (stored == null) return defaultValue;
    return stored == 1;
  }

  Future<void> setReminderEnabled(bool enabled) async {
    await settingsBox.put(StorageKeys.reminderEnabled, enabled ? 1 : 0);
  }

  /// Reminder time as minutes since midnight (0-1439). Defaults to 08:00.
  int getReminderTime({int defaultValue = 8 * 60}) {
    return settingsBox.get(StorageKeys.reminderTime,
            defaultValue: defaultValue) ??
        defaultValue;
  }

  Future<void> setReminderTime(int minutesSinceMidnight) async {
    await settingsBox.put(StorageKeys.reminderTime, minutesSinceMidnight);
  }

  bool getMoodReminderEnabled({bool defaultValue = false}) {
    final stored = settingsBox.get(StorageKeys.moodReminderEnabled);
    if (stored == null) return defaultValue;
    return stored == 1;
  }

  Future<void> setMoodReminderEnabled(bool enabled) async {
    await settingsBox.put(StorageKeys.moodReminderEnabled, enabled ? 1 : 0);
  }

  /// Mood reminder time as minutes since midnight. Defaults to 09:00.
  int getMoodReminderTime({int defaultValue = 9 * 60}) {
    return settingsBox.get(StorageKeys.moodReminderTime,
            defaultValue: defaultValue) ??
        defaultValue;
  }

  Future<void> setMoodReminderTime(int minutesSinceMidnight) async {
    await settingsBox.put(StorageKeys.moodReminderTime, minutesSinceMidnight);
  }

  bool getOvulationReminderEnabled({bool defaultValue = false}) {
    final stored = settingsBox.get(StorageKeys.ovulationReminderEnabled);
    if (stored == null) return defaultValue;
    return stored == 1;
  }

  Future<void> setOvulationReminderEnabled(bool enabled) async {
    await settingsBox.put(
        StorageKeys.ovulationReminderEnabled, enabled ? 1 : 0);
  }

  /// Ovulation reminder time as minutes since midnight. Defaults to 08:00.
  int getOvulationReminderTime({int defaultValue = 8 * 60}) {
    return settingsBox.get(StorageKeys.ovulationReminderTime,
            defaultValue: defaultValue) ??
        defaultValue;
  }

  Future<void> setOvulationReminderTime(int minutesSinceMidnight) async {
    await settingsBox.put(
        StorageKeys.ovulationReminderTime, minutesSinceMidnight);
  }

  bool getPhaseReminderEnabled({bool defaultValue = false}) {
    final stored = settingsBox.get(StorageKeys.phaseReminderEnabled);
    if (stored == null) return defaultValue;
    return stored == 1;
  }

  Future<void> setPhaseReminderEnabled(bool enabled) async {
    await settingsBox.put(StorageKeys.phaseReminderEnabled, enabled ? 1 : 0);
  }

  /// Phase-change reminder time as minutes since midnight. Defaults to 08:00.
  int getPhaseReminderTime({int defaultValue = 8 * 60}) {
    return settingsBox.get(StorageKeys.phaseReminderTime,
            defaultValue: defaultValue) ??
        defaultValue;
  }

  Future<void> setPhaseReminderTime(int minutesSinceMidnight) async {
    await settingsBox.put(StorageKeys.phaseReminderTime, minutesSinceMidnight);
  }

  /// How many days before the predicted period start the reminder window
  /// should begin. Defaults to 3.
  int getPeriodLeadDays({int defaultValue = 3}) {
    return settingsBox.get(StorageKeys.periodLeadDays,
            defaultValue: defaultValue) ??
        defaultValue;
  }

  Future<void> setPeriodLeadDays(int days) async {
    await settingsBox.put(StorageKeys.periodLeadDays, days);
  }

  bool getDarkMode({bool defaultValue = false}) {
    final options = optionsBox.get('theme');
    return options?.darkMode ?? defaultValue;
  }

  Future<void> setDarkMode(bool isDark) async {
    var options = optionsBox.get('theme') ?? Options();
    options.darkMode = isDark;
    await optionsBox.put('theme', options);
  }

  Future<void> clearAllData() async {
    await dailyDataBox.clear();
    await settingsBox.clear();
    await optionsBox.clear();
  }

  String _dateToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Stable Hive key for a daily-data entry, shared with import/export.
  String keyForDate(DateTime date) => _dateToKey(date);
}
