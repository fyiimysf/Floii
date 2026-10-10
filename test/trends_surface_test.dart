import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:floi/screens/trends/trends_screen.dart';
import 'package:floi/screens/trends/widgets/cycle_length_chart.dart';
import 'package:floi/screens/trends/widgets/distribution_card.dart';
import 'package:floi/screens/trends/widgets/regularity_card.dart';
import 'package:floi/utils/constants/dimensions.dart';
import 'package:floi/widgets/common/cards.dart';
import 'package:floi/widgets/common/dashboard_surface.dart';

/// Several cycles, so every section has something real to show.
Map<String, dynamic> makeStats() {
  final now = DateTime.now();
  return {
    'average': 28,
    'prediction': now.add(const Duration(days: 6)),
    'periods': <List<DateTime>>[
      for (var i = 5; i >= 1; i--)
        [
          now.subtract(Duration(days: 28 * i + 4)),
          now.subtract(Duration(days: 28 * i)),
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
  final dir = Directory.systemTemp.createTempSync('trends_surface_test');
  Hive.init(dir.path);
  if (!_adaptersRegistered) {
    await Hive.openBox<Map<dynamic, dynamic>>('periods');
    await Hive.openBox<Map<dynamic, dynamic>>('options');
    _adaptersRegistered = true;
  }
}

Future<void> showTrends(WidgetTester tester) async {
  await tester.runAsync(openBoxes);
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: TrendsScreen(stats: makeStats()))),
  );
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('the four analyses share one surface, not four cards',
      (tester) async {
    await showTrends(tester);

    expect(find.byType(DashboardSurface), findsOneWidget,
        reason: 'trends should be a single panel like the insights page');

    // The sections used to each bring their own card, which nested a second
    // card inside the panel.
    expect(find.byType(ClayCard), findsNothing,
        reason: 'a section is still drawing its own card inside the surface');

    // All four sections are present on that one surface.
    expect(find.byType(RegularityCard), findsOneWidget);
    expect(find.byType(CycleLengthChart), findsOneWidget);
    expect(find.byType(DistributionCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sections are separated by insets, not by touching edges',
      (tester) async {
    await showTrends(tester);

    // Four sections means three hairlines between them.
    expect(find.byType(DashboardSectionDivider), findsNWidgets(3));

    // Every section is inset from the panel edge, so content cannot touch it.
    final inset =
        dashboardSectionInset(tester.element(find.byType(DashboardSurface)));
    expect(inset, greaterThanOrEqualTo(8));
  });

  testWidgets('a card that asks for no padding still gets breathing room',
      (tester) async {
    // This used to fall back to an elevation constant (4.0), which left the
    // content hard against the border on 16 cards across the app.
    const key = Key('content');
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: ClayCard(child: SizedBox(key: key, width: 40, height: 40)),
        ),
      ),
    ));

    final card = tester.getRect(find.byType(ClayCard));
    final content = tester.getRect(find.byKey(key));

    expect(content.left - card.left, greaterThanOrEqualTo(16),
        reason: 'the content is flush against the card edge');
    expect(content.top - card.top, greaterThanOrEqualTo(16));
    expect(AppDimensions.cardPadding, greaterThanOrEqualTo(16),
        reason: 'guard: the two constants must not be conflated again');
  });

  testWidgets('section content clears the panel edge', (tester) async {
    await showTrends(tester);

    final surfaceLeft = tester.getTopLeft(find.byType(DashboardSurface)).dx;
    final chartLeft = tester.getTopLeft(find.byType(CycleLengthChart)).dx;

    expect(chartLeft - surfaceLeft, greaterThanOrEqualTo(8),
        reason: 'the chart is flush against the panel edge');
  });
}
