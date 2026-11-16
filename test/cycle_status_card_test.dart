import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:floi/models/enums.dart';
import 'package:floi/screens/home/widgets/cycle_phase_strip.dart';
import 'package:floi/screens/home/widgets/cycle_status_card.dart';
import 'package:floi/services/localization/app_localizations.dart';

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

Widget wrap(Widget child, {double width = 400}) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: const [Locale('en')],
    localizationsDelegates: const [AppLocalizations.delegate],
    home: Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('flagship dashboard shows day, phase, hint and predictions',
      (tester) async {
    await tester.pumpWidget(
      wrap(CycleStatusCard(stats: dashboardStats())),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Day-of-cycle is the central number inside the semi donut.
    expect(find.text('10th'), findsOneWidget);
    expect(find.text('day of 28'), findsOneWidget);

    // Phase title with tiny heading + hint subtext below the donut.
    expect(find.text('CURRENT PHASE'), findsOneWidget);
    expect(find.text('Follicular'), findsAtLeastNWidgets(1));
    expect(
      find.text('Feeling energetic, focused and creative'),
      findsOneWidget,
    );

    // The expandable cycle phase strip now lives inside the card.
    expect(find.byType(CyclePhaseStrip), findsOneWidget);
    expect(find.text('Luteal'), findsWidgets);

    // Next-prediction mini tiles.
    expect(find.text('Next Period'), findsOneWidget);
    expect(find.text('Consistency'), findsOneWidget);
    expect(find.text('19 days'), findsOneWidget);
    expect(find.text('5 days'), findsOneWidget);
    await tester.ensureVisible(find.text('Menstrual').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menstrual').first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
  });

  testWidgets('dashboard has no overflow on a narrow phone', (tester) async {
    await tester.pumpWidget(
      wrap(CycleStatusCard(stats: dashboardStats()), width: 300),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty stats keeps the welcome empty state', (tester) async {
    await tester.pumpWidget(
      wrap(CycleStatusCard(
          stats: {'periods': <List<DateTime>>[], 'average': 28})),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Floii!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mood button keeps one styling whether or not a mood is set',
      (tester) async {
    // Selecting a mood used to restyle and resize the button, because the
    // logged mood was drawn as a Text holding its emoji: that sized itself
    // from the glyph's metrics rather than the icon slot, so it drew smaller,
    // stretched the button and inherited the ambient text colour. Both states
    // now build one Icon and must be indistinguishable.
    final buttons = <Mood?, Size>{};
    final icons = <Mood?, Rect>{};
    final colours = <Mood?, Color?>{};

    for (final mood in <Mood?>[null, ...Mood.values]) {
      await tester.pumpWidget(
        wrap(CycleStatusCard(
          stats: dashboardStats(),
          currentMood: mood,
          onMoodTap: () {},
        )),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final icon = find.byIcon(mood?.icon ?? Icons.mood_outlined);
      expect(icon, findsOneWidget, reason: 'mood=$mood');

      final button = find.ancestor(of: icon, matching: find.byType(IconButton));
      expect(button, findsOneWidget);

      buttons[mood] = tester.getSize(button.first);
      icons[mood] = tester.getRect(icon);
      colours[mood] = tester.widget<Icon>(icon).color;
    }

    for (final mood in Mood.values) {
      expect(buttons[mood], buttons[null],
          reason: 'mood=$mood resized the button');
      expect(icons[mood]!.size, icons[null]!.size,
          reason: 'mood=$mood changed the icon size');
      expect(icons[mood]!.center, icons[null]!.center,
          reason: 'mood=$mood moved the icon');
      expect(colours[mood], colours[null],
          reason: 'mood=$mood colour differs from the default icon');
    }

    expect(buttons[null], const Size(48, 48));
    expect(icons[null]!.size, const Size(32, 32));

    // Every mood needs a distinct icon, and none may collide with the
    // "no mood logged" placeholder.
    final icons2 = Mood.values.map((m) => m.icon).toSet();
    expect(icons2, hasLength(Mood.values.length));
    expect(icons2, isNot(contains(Icons.mood_outlined)));
  });
}
