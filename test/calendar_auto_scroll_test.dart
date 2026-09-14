import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floi/screens/calendar/calendar_year_view.dart';

void main() {
  Widget harness(bool visible, {required GlobalKey<CycleYearViewState> key}) {
    final stats = <String, dynamic>{
      'periods': <List<DateTime>>[],
      'average': 28,
      'currentPeriodLength': 5,
    };
    return MaterialApp(
      home: Scaffold(
        body: visible
            ? CycleYearView(key: key, stats: stats)
            : IndexedStack(
                index: 0,
                children: [const SizedBox(), CycleYearView(key: key, stats: stats)],
              ),
      ),
    );
  }

  testWidgets('visible CycleYearView auto-scrolls to current month',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey<CycleYearViewState>();
    await tester.pumpWidget(harness(true, key: key));
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CycleYearView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    expect(scrollable.position.pixels, greaterThan(0));
  });

  testWidgets('bill-scrolled from shell when calendar tab becomes visible',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey<CycleYearViewState>();
    await tester.pumpWidget(harness(false, key: key));
    await tester.pumpAndSettle();

    // emulate MainShell._goTo(1): switch the IndexedStack to show the calendar
    // then call scrollToCurrentMonth on the now-visible state.
    key.currentState!.scrollToCurrentMonth();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CycleYearView, skipOffstage: false),
            matching: find.byType(Scrollable, skipOffstage: false),
          )
          .first,
    );
    expect(scrollable.position.pixels, greaterThan(0));
  });
}
