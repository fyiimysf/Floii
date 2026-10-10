import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:floi/models/cycle_models.dart';
import 'package:floi/screens/insights/insights_screen.dart';
import 'package:floi/screens/home/home_screen.dart';
import 'package:floi/screens/settings/settings_screen.dart';
import 'package:floi/screens/settings/about_screen.dart';
import 'package:floi/screens/settings/help_faq_screen.dart';
import 'package:floi/screens/settings/feedback_screen.dart';
import 'package:floi/screens/settings/notifications_screen.dart';
import 'package:floi/screens/trends/trends_screen.dart';
import 'package:floi/screens/calendar/calendar_year_view.dart';

Map<String, dynamic> makeStats() {
  final now = DateTime.now();
  return {
    'average': 28,
    'prediction': now.add(const Duration(days: 6)),
    'periods': <List<DateTime>>[
      [
        now.subtract(const Duration(days: 20)),
        now.subtract(const Duration(days: 16)),
      ],
    ],
    'cycleLengths': <int>[],
    'periodLengths': <int>[5],
    'ovulationDate': now.add(const Duration(days: 1)),
    'fertileWindowStart': now.subtract(const Duration(days: 4)),
    'fertileWindowEnd': now.add(const Duration(days: 1)),
    'currentPeriodLength': 5,
  };
}

bool _adaptersRegistered = false;

Future<void> openBoxes() async {
  final dir = Directory.systemTemp.createTempSync('flowy_test');
  Hive.init(dir.path);
  if (!_adaptersRegistered) {
    Hive.registerAdapter(DailyDataAdapter());
    Hive.registerAdapter(OptionsAdapter());
    _adaptersRegistered = true;
  }
  await Hive.openBox<int>('settings');
  await Hive.openBox<Options>('options');
  await Hive.openBox<DailyData>('dailyData');
}

void setPhoneSize(WidgetTester tester, Size logical) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = logical;
  addTearDown(tester.view.reset);
}

void main() {
  final screens = <String, Widget Function()>{
    'insights': () => InsightsScreen(stats: makeStats()),
    'home': () => HomeScreen(stats: makeStats()),
    'calendar': () => CycleYearView(stats: makeStats(), showHeader: true),
    'settings': () => const SettingsScreen(),
    'about': () => const AboutScreen(),
    'helpFaq': () => const HelpFaqScreen(),
    'feedback': () => const FeedbackScreen(),
    'notifications': () => const NotificationsScreen(),
    'trends': () => TrendsScreen(stats: makeStats()),
  };

  for (final size in const [Size(320, 640), Size(390, 844)]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} has no overflow @${size.width.toInt()}',
          (tester) async {
        await tester.runAsync(openBoxes);
        addTearDown(() async {
          await Hive.close();
        });
        setPhoneSize(tester, size);
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: entry.value())),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
        final e = tester.takeException();
        expect(e, isNull,
            reason: '${entry.key} overflow '
                '${size.width.toInt()}x${size.height.toInt()}');
      });
    }
  }

  testWidgets('insights has no overflow at 2x text scale', (tester) async {
    setPhoneSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data:
              const MediaQueryData().copyWith(textScaler: TextScaler.linear(2)),
          child: Scaffold(body: InsightsScreen(stats: makeStats())),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    final e = tester.takeException();
    expect(e, isNull, reason: 'insights overflow at 2x text scale');
  });
}
