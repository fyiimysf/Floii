import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:floi/models/cycle_models.dart';
import 'package:floi/screens/home/widgets/calendar_widget.dart';

Map<String, dynamic> emptyStats() => {
      'periods': <List<DateTime>>[],
      'average': 28,
      'currentPeriodLength': 5,
    };

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('title_grid_sync_test');
    Hive.init(tempDir.path);
    Hive.registerAdapter(DailyDataAdapter());
    await Hive.openBox<DailyData>('dailyData');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('dragging the month title scrolls the grid', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);

    final initial = monthPageIndex(DateTime(2026, 3, 1));
    final changed = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarWidget(
            currentMonth: DateTime(2026, 3),
            predictedPeriods: <DateTime>[],
            stats: emptyStats(),
            pageController: PageController(initialPage: initial),
            onPageChanged: changed.add,
            onDateTap: (_, __) {},
            onDateLongPress: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('calendarMonthTitle')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();

    final gridPage = tester
        .widget<PageView>(find.byKey(const ValueKey('calendarMonthGrid')))
        .controller!
        .page!
        .round();
    expect(gridPage, initial + 1,
        reason: 'dragging title to next month should move grid to next month');
    expect(changed, contains(initial + 1));
    expect(tester.takeException(), isNull);
  });
}