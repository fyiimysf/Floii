import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floi/app_text_scaling.dart';
import 'package:floi/screens/insights/insights_screen.dart';

Future<double> effectiveScale(WidgetTester tester, Size size,
    {double textScale = 1.0}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.textScaleFactorTestValue = 1.0;
  });
  double captured = 0;
  await tester.pumpWidget(
    MaterialApp(
      builder: buildAppTextScaling,
      home: Builder(
        builder: (context) {
          captured = MediaQuery.textScalerOf(context).scale(1);
          return const SizedBox();
        },
      ),
    ),
  );
  return captured;
}

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
  testWidgets('clamps widths to 0.9 / 1.0 / 1.1', (tester) async {
    expect(await effectiveScale(tester, const Size(320, 640)), closeTo(0.9, 1e-9));
    expect(await effectiveScale(tester, const Size(390, 844)), closeTo(1.0, 1e-9));
    expect(await effectiveScale(tester, const Size(800, 1280)), closeTo(1.1, 1e-9));
  });

  testWidgets('system text scale is preserved, not clamped away',
      (tester) async {
    final scale = await effectiveScale(tester, const Size(320, 640),
        textScale: 2.0);
    expect(scale, closeTo(1.8, 1e-9));
  });

  testWidgets('insights has no overflow on small screen with clamp active',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: buildAppTextScaling,
        home: Scaffold(body: InsightsScreen(stats: makeStats())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    final e = tester.takeException();
    expect(e, isNull, reason: 'insights overflow on 320x640 with clamp');
  });
}