import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:floi/models/cycle_models.dart';
import 'package:floi/screens/calendar/calendar_year_view.dart';
import 'package:floi/widgets/common/cycle_day_cell.dart';

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

void main() {
  bool adaptersRegistered = false;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('calendar_year_test');
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

  Future<void> pumpYearView(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CycleYearView(stats: makeStats(), showHeader: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('app bar action shows the selected year', (tester) async {
    await pumpYearView(tester);

    final year = '${DateTime.now().year}';
    expect(
      find.descendant(
        of: find.byType(SliverAppBar),
        matching: find.text(year),
      ),
      findsOneWidget,
    );
  });

  testWidgets('mini month grids reuse the home CycleDayCell', (tester) async {
    await pumpYearView(tester);

    expect(find.byType(CycleDayCell), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
