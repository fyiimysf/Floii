import 'package:flutter/material.dart';
import 'app.dart';
import 'models/cycle_models.dart';
import 'services/localization/language_service.dart';
import 'services/notifications/notification_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(DailyDataAdapter());
  Hive.registerAdapter(OptionsAdapter());

  await Hive.openBox<int>('settings');
  await Hive.openBox<Options>('options');
  await Hive.openBox<DailyData>('dailyData');

  await LanguageService().init();

  final notifications = NotificationService();
  try {
    await notifications.init();
    await notifications.syncReminder();
  } catch (e) {
    // Notification setup must never block app startup, but log failures so
    // reminder issues are visible in the console during development.
    debugPrint('Failed to initialize notifications: $e');
  }

  runApp(const FloiiApp());
}
