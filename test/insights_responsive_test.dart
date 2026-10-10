import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:floi/models/cycle_models.dart';
import 'package:floi/screens/insights/insights_screen.dart';
import 'package:floi/utils/responsive.dart';

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
      [
        now.subtract(const Duration(days: 48)),
        now.subtract(const Duration(days: 44)),
      ],
      [
        now.subtract(const Duration(days: 76)),
        now.subtract(const Duration(days: 72)),
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
  final dir = Directory.systemTemp.createTempSync('floii_responsive_test');
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

/// Every text run in the tree that is clipped by its own `maxLines` limit —
/// i.e. text that ends up cut off or ellipsized on screen.
List<String> truncatedText(WidgetTester tester) {
  final out = <String>{};
  for (final paragraph
      in tester.allRenderObjects.whereType<RenderParagraph>()) {
    if (paragraph.maxLines != null && paragraph.didExceedMaxLines) {
      out.add(paragraph.text.toPlainText());
    }
  }
  return out.toList()..sort();
}

int _gridColumns(WidgetTester tester) {
  final grid = tester.widget<GridView>(find.byType(GridView).first);
  final delegate =
      grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
  return delegate.crossAxisCount;
}

void main() {
  group('ScreenSize bucketing', () {
    test('splits widths at the compact/expanded breakpoints', () {
      expect(ScreenSize.fromWidth(320), ScreenSize.compact);
      expect(ScreenSize.fromWidth(360), ScreenSize.compact);
      expect(ScreenSize.fromWidth(379), ScreenSize.compact);
      expect(ScreenSize.fromWidth(390), ScreenSize.regular);
      expect(ScreenSize.fromWidth(430), ScreenSize.regular);
      expect(ScreenSize.fromWidth(600), ScreenSize.expanded);
      expect(ScreenSize.fromWidth(1024), ScreenSize.expanded);
    });

    test('uses the shortest side so landscape buckets sensibly', () {
      expect(ScreenSize.fromSize(const Size(844, 390)), ScreenSize.regular);
      expect(ScreenSize.fromSize(const Size(640, 320)), ScreenSize.compact);
      expect(ScreenSize.fromSize(const Size(1024, 768)), ScreenSize.expanded);
    });

    test('grid is two columns when small, three otherwise', () {
      expect(ScreenSize.compact.gridColumns, 2);
      expect(ScreenSize.regular.gridColumns, 3);
      expect(ScreenSize.expanded.gridColumns, 3);
    });
  });

  group('insights grid columns', () {
    testWidgets('two columns on a small screen', (tester) async {
      await tester.runAsync(openBoxes);
      addTearDown(() async => Hive.close());
      setPhoneSize(tester, const Size(320, 640));
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: InsightsScreen(stats: makeStats()))),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(_gridColumns(tester), 2);
    });

    testWidgets('three columns on a larger screen', (tester) async {
      await tester.runAsync(openBoxes);
      addTearDown(() async => Hive.close());
      setPhoneSize(tester, const Size(430, 900));
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: InsightsScreen(stats: makeStats()))),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(_gridColumns(tester), 3);
    });
  });

  group('insights text is not truncated', () {
    for (final width in const [320.0, 360.0, 390.0, 430.0]) {
      testWidgets('nothing is ellipsized at ${width.toInt()}px wide',
          (tester) async {
        await tester.runAsync(openBoxes);
        addTearDown(() async => Hive.close());
        setPhoneSize(tester, Size(width, 900));
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData()
                  .copyWith(textScaler: TextScaler.linear(1.3)),
              child: Scaffold(body: InsightsScreen(stats: makeStats())),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull,
            reason: 'overflow at ${width.toInt()}px');
        expect(truncatedText(tester), isEmpty,
            reason: 'clipped text at ${width.toInt()}px');
      });
    }
  });
}
