import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:floi/screens/home/widgets/cycle_phase_strip.dart';

Map<String, dynamic> cycleStats() {
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day - 10, 12);
  return {
    'periods': [
      [start, start.add(const Duration(days: 4))],
    ],
    'average': 28,
    'currentPeriodLength': 5,
  };
}

void main() {
  testWidgets('renders current phase header and phase labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: CyclePhaseStrip(stats: cycleStats()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Midnight start minus 10 days puts today inside the follicular phase.
    expect(find.text('Follicular'), findsAtLeastNWidgets(1));
    expect(find.text('Menstrual'), findsOneWidget);
    expect(find.text('Ovulation'), findsOneWidget);
    expect(find.text('Luteal'), findsOneWidget);
    expect(find.byType(AnimatedFractionallySizedBox), findsOneWidget);
  });

  testWidgets('tapping the strip expands phase details', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: CyclePhaseStrip(stats: cycleStats()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Collapsed: each phase name appears once (label row), no descriptions.
    expect(find.text('Ovulation'), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb_outline), findsNothing);

    await tester.tap(find.text('Follicular').first);
    await tester.pumpAndSettle();

    // Expanded: detail rows add one more copy of each phase name plus dates
    // and the current-phase description.
    expect(find.text('Ovulation'), findsNWidgets(2));
    expect(find.textContaining(' - '), findsWidgets);
    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('short without data expands to nothing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CyclePhaseStrip(
            stats: {'periods': <List<DateTime>>[], 'average': 28},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Menstrual'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
