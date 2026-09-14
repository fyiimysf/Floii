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
    tempDir = await Directory.systemTemp.createTemp('home_calendar_test');
    Hive.init(tempDir.path);
    Hive.registerAdapter(DailyDataAdapter());
    await Hive.openBox<DailyData>('dailyData');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('legend phase indicators scale down instead of wrapping',
      (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(320 * 3, 900 * 3);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(
        () => tester.platformDispatcher.clearTextScaleFactorTestValue());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CalendarWidget(
              predictedPeriods: <DateTime>[],
              stats: emptyStats(),
              pageController: PageController(
                initialPage: monthPageIndex(DateTime(2026, 9)),
              ),
              onPageChanged: (_) {},
              onDateTap: (_, __) {},
              onDateLongPress: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // The legend is rendered through a scale-down FittedBox so it can never
    // wrap to a second run: all four phase labels share one vertical center.
    expect(
      tester
          .widgetList<FittedBox>(find.byType(FittedBox))
          .where((box) => box.fit == BoxFit.scaleDown),
      isNotEmpty,
    );

    final centers = ['period', 'fertile', 'ovulationPhase', 'predicted']
        .map((key) => tester.getCenter(find.text(key)).dy)
        .toList();
    for (final y in centers) {
      expect(y, closeTo(centers.first, 2));
    }
  });

  testWidgets('swiping the paged calendar changes months', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    final initial = monthPageIndex(DateTime(2026, 3, 1));
    final changed = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarWidget(
            predictedPeriods: <DateTime>[],
            stats: emptyStats(),
            currentMonth: DateTime(2026, 3),
            pageController: PageController(initialPage: initial),
            onPageChanged: changed.add,
            onDateTap: (_, __) {},
            onDateLongPress: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(changed, isEmpty);

    await tester.drag(
        find.byKey(const ValueKey('calendarMonthGrid')), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(changed.last, initial + 1);

    await tester.drag(
        find.byKey(const ValueKey('calendarMonthGrid')), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(changed.last, initial);
    // Adjacent-month silhouette chips replace the chevron nav buttons.
    expect(find.text('Feb'), findsOneWidget);
    expect(find.text('Apr'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('static calendar renders a single month without paging',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CalendarWidget(
              currentMonth: DateTime(2026, 9),
              predictedPeriods: <DateTime>[],
              stats: emptyStats(),
              onDateTap: (_, __) {},
              onDateLongPress: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsNothing);
    expect(find.text('Feb'), findsNothing);
    expect(find.text('Apr'), findsNothing);
    expect(tester.takeException(), isNull);
  });
testWidgets('month title scales down instead of wrapping', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(
        () => tester.platformDispatcher.clearTextScaleFactorTestValue());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: CalendarWidget(
                currentMonth: DateTime(2026, 9),
                predictedPeriods: <DateTime>[],
                stats: emptyStats(),
                onDateTap: (_, __) {},
                onDateLongPress: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // The title sits inside a scale-down FittedBox; even at 1.6x font scaling
    // the header must stay a single line (it would exceed if wrapped).
    expect(
      find.byWidgetPredicate(
        (w) => w is FittedBox && w.fit == BoxFit.scaleDown,
      ),
      findsWidgets,
    );
  });
}