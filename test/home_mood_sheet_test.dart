import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:floi/models/cycle_models.dart';
import 'package:floi/models/enums.dart';
import 'package:floi/screens/home/dialogs/mood_picker_sheet.dart';
import 'package:floi/screens/home/home_screen.dart';
import 'package:floi/screens/home/widgets/cycle_status_card.dart';
import 'package:floi/services/localization/app_localizations.dart';
import 'package:floi/utils/constants/colors.dart';

const _moodTooltip = 'How are you feeling today?';

Map<String, dynamic> dashboardStats() {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day - 9);
  return {
    'periods': [
      [start, start.add(const Duration(days: 4))],
    ],
    'average': 28,
    'currentPeriodLength': 5,
    'cycleLengths': <int>[],
    'periodLengths': [5],
    'prediction': start.add(const Duration(days: 28)),
    'ovulationDate': start.add(const Duration(days: 14)),
  };
}

bool _adaptersRegistered = false;

Future<void> openBoxes() async {
  final dir = Directory.systemTemp.createTempSync('floii_mood_sheet_test');
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

Widget app(Widget home, {double textScale = 1.0}) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: const [Locale('en')],
    localizationsDelegates: const [AppLocalizations.delegate],
    // Derived from the view so `MediaQuery.sizeOf` still reports a real
    // screen width and the responsive buckets are exercised for real.
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: home),
      ),
    ),
  );
}

/// Card sized like a phone screen so `MediaQuery.sizeOf` reports a real width.
Widget cardPage(Widget card, {double width = 400}) {
  return app(
    Center(
      child: SingleChildScrollView(
        child: SizedBox(width: width, child: card),
      ),
    ),
  );
}

void setPhoneSize(WidgetTester tester, Size logical) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = logical;
  addTearDown(tester.view.reset);
}

int gridColumns(WidgetTester tester) {
  // Scoped to the sheet: the home calendar also renders a GridView.
  final grid = tester.widget<GridView>(
    find.descendant(
      of: find.byType(MoodPickerSheet),
      matching: find.byType(GridView),
    ),
  );
  return (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
      .crossAxisCount;
}

/// Rect of the [IconButton] wrapping [icon] — the hit target, not the glyph.
Rect iconButtonRect(WidgetTester tester, IconData icon) => tester.getRect(
      find
          .ancestor(of: find.byIcon(icon), matching: find.byType(IconButton))
          .first,
    );

/// Border colour of a mood tile, which is how selection is rendered.
Color _moodBorderColor(WidgetTester tester, Mood mood) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byKey(ValueKey('moodTile-${mood.name}')),
          matching: find.byType(Container),
        )
        .first,
  );
  return (container.decoration! as BoxDecoration).border!.top.color;
}

void main() {
  group('status card controls', () {
    testWidgets('collapse sits on the left, mood on the right', (tester) async {
      await tester.pumpWidget(
        cardPage(CycleStatusCard(
          stats: dashboardStats(),
          onToggleCollapsed: () {},
          onMoodTap: () {},
        )),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final card = tester.getRect(find.byType(CycleStatusCard));
      final collapse = iconButtonRect(tester, Icons.keyboard_arrow_up_rounded);
      final mood = iconButtonRect(tester, Icons.mood_outlined);

      // Each control hugs its own edge, allowing for the card's border+padding
      // (2 + 12) that the Stack sits inside.
      expect(collapse.center.dx, lessThan(card.center.dx));
      expect(mood.center.dx, greaterThan(card.center.dx));
      expect(collapse.left - card.left, lessThanOrEqualTo(14));
      expect(card.right - mood.right, lessThanOrEqualTo(14));
    });

    testWidgets('mood button shows the logged mood and reports taps',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        cardPage(CycleStatusCard(
          stats: dashboardStats(),
          currentMood: Mood.happy,
          onMoodTap: () => tapped++,
        )),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // The placeholder icon is replaced by today's logged mood.
      expect(find.byIcon(Icons.mood_outlined), findsNothing);
      expect(find.byIcon(Mood.happy.icon), findsOneWidget);

      await tester.tap(find.byTooltip(_moodTooltip));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });

    testWidgets('mood button is hidden when no handler is given',
        (tester) async {
      await tester
          .pumpWidget(cardPage(CycleStatusCard(stats: dashboardStats())));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.mood_outlined), findsNothing);
    });

    testWidgets('collapsed card keeps expand left and mood right',
        (tester) async {
      await tester.pumpWidget(
        cardPage(CycleStatusCard(
          stats: dashboardStats(),
          collapsed: true,
          onToggleCollapsed: () {},
          onMoodTap: () {},
        )),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final card = tester.getRect(find.byType(CycleStatusCard));
      final expand = iconButtonRect(tester, Icons.keyboard_arrow_down_rounded);
      final mood = iconButtonRect(tester, Icons.mood_outlined);

      expect(expand.center.dx, lessThan(card.center.dx));
      expect(mood.center.dx, greaterThan(card.center.dx));
    });

    testWidgets('collapsed card fits a narrow phone with a logged mood',
        (tester) async {
      setPhoneSize(tester, const Size(320, 640));
      await tester.pumpWidget(
        cardPage(
          CycleStatusCard(
            stats: dashboardStats(),
            collapsed: true,
            onToggleCollapsed: () {},
            onMoodTap: () {},
            currentMood: Mood.energetic,
          ),
          width: 320,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty state keeps mood logging available', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        cardPage(CycleStatusCard(
          stats: {'periods': <List<DateTime>>[], 'average': 28},
          onMoodTap: () => tapped++,
        )),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Welcome to Floii!'), findsOneWidget);
      expect(find.byIcon(Icons.mood_outlined), findsOneWidget);

      await tester.tap(find.byTooltip(_moodTooltip));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });
  });

  group('mood picker sheet', () {
    testWidgets('offers every mood in a grid and returns the saved pick',
        (tester) async {
      Mood? result;
      setPhoneSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        app(Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await Navigator.push<Mood>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      body: SingleChildScrollView(child: MoodPickerSheet()),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        )),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.byType(GridView), findsOneWidget);
      for (final mood in Mood.values) {
        expect(find.byIcon(mood.icon), findsOneWidget);
      }
      expect(find.text('Save'), findsOneWidget);

      // Compact: the whole sheet stays well under half a phone screen, so
      // there is no dead space around the grid.
      expect(
        tester.getSize(find.byType(MoodPickerSheet)).height,
        lessThan(380),
      );

      await tester.tap(find.byIcon(Mood.energetic.icon));
      await tester.pumpAndSettle();
      // The sheet scrolls, so the save action may sit below the fold.
      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(result, Mood.energetic);
    });

    testWidgets('preselects the mood passed in', (tester) async {
      await tester.pumpWidget(
        app(const Scaffold(
          body: SingleChildScrollView(
            child: MoodPickerSheet(selected: Mood.sad),
          ),
        )),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Only the preselected tile carries the accent border.
      expect(_moodBorderColor(tester, Mood.sad), AppColors.secondary);
      expect(_moodBorderColor(tester, Mood.happy), isNot(AppColors.secondary));
    });

    testWidgets('grid is two columns of three on every screen size',
        (tester) async {
      setPhoneSize(tester, const Size(320, 640));
      await tester.pumpWidget(
        app(const SingleChildScrollView(
          child: SizedBox(width: 320, child: MoodPickerSheet()),
        )),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(gridColumns(tester), 2);
      // Wide enough to be a real tap target, not a token bubble.
      expect(
        tester.getSize(find.byKey(const ValueKey('moodTile-happy'))).width,
        greaterThan(100),
      );

      setPhoneSize(tester, const Size(430, 900));
      await tester.pumpWidget(
        app(const SingleChildScrollView(
          child: SizedBox(width: 430, child: MoodPickerSheet()),
        )),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(gridColumns(tester), 2);

      // Three rows: six moods, two per row.
      final tiles = Mood.values
          .map(
              (m) => tester.getRect(find.byKey(ValueKey('moodTile-${m.name}'))))
          .toList();
      final rows = tiles.map((r) => r.top).toSet().length;
      expect(rows, 3);
    });

    testWidgets('no overflow on a small phone with large system text',
        (tester) async {
      setPhoneSize(tester, const Size(320, 560));
      await tester.pumpWidget(
        app(
          const SingleChildScrollView(
            child: SizedBox(width: 320, child: MoodPickerSheet()),
          ),
          textScale: 1.6,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('home opens the mood sheet from the status card', (tester) async {
    await tester.runAsync(openBoxes);
    addTearDown(() async => Hive.close());
    setPhoneSize(tester, const Size(390, 844));
    await tester.pumpWidget(app(HomeScreen(stats: dashboardStats())));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    // The dedicated mood card that used to sit below the status card is gone:
    // the sheet's prompt is not on the page.
    expect(find.text(_moodTooltip), findsNothing);

    await tester.tap(find.byTooltip(_moodTooltip));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // The sheet carries the prompt plus the grid of mood buttons.
    expect(find.text(_moodTooltip), findsOneWidget);
    for (final mood in Mood.values) {
      expect(find.byIcon(mood.icon), findsOneWidget);
    }
    expect(gridColumns(tester), 2);

    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Saving dismisses the sheet and returns to the page.
    expect(find.text(_moodTooltip), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
