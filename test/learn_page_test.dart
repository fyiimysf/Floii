import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:floi/content/learn/learn_article.dart';
import 'package:floi/content/learn/learn_content.dart';
import 'package:floi/models/cycle_models.dart';
import 'package:floi/models/learn_topic.dart';
import 'package:floi/screens/home/home_screen.dart';
import 'package:floi/services/localization/app_localizations.dart';
import 'package:floi/screens/learn/learn_screen.dart';
import 'package:floi/screens/learn/learn_topic_screen.dart';
import 'package:floi/utils/constants/colors.dart';
import 'package:floi/widgets/common/cards.dart';

/// Every styled run currently rendered by the pumped widget tree.
Iterable<TextStyle> _styledRuns(WidgetTester tester) sync* {
  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    final children = rich.text;
    if (children is! TextSpan) continue;
    yield* _spanStyles(children);
  }
}

Iterable<TextStyle> _spanStyles(InlineSpan span) sync* {
  if (span is TextSpan) {
    if (span.text?.isNotEmpty ?? false) {
      yield span.style ?? const TextStyle();
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      yield* _spanStyles(child);
    }
  }
}

/// True when every occurrence of [marker] can be paired off.
bool _balanced(String text, String marker) {
  var count = 0;
  var index = text.indexOf(marker);
  while (index != -1) {
    count++;
    index = text.indexOf(marker, index + marker.length);
  }
  return count.isEven;
}

/// The article text as the reader actually sees it, once the markup is
/// applied. Compared against `RichText.toPlainText`, so this also proves the
/// markers were consumed rather than printed.
String _stripped(String text) =>
    text.replaceAll(RegExp(r'\*\*|!!'), '').replaceAllMapped(
          RegExp(r'(?<![A-Za-z0-9])_(.+?)(?<![A-Za-z0-9])_'),
          (m) => m.group(1)!,
        );

void _expectAppBarHeight(WidgetTester tester, double height) {
  final appBar = find.byType(SliverAppBar);
  expect(appBar, findsOneWidget);
  final widget = tester.widget<SliverAppBar>(appBar);
  expect(widget.expandedHeight, height);
  expect(widget.collapsedHeight, height);
  expect(widget.toolbarHeight, height);
}

Widget app(
  Widget home, {
  Locale locale = const Locale('en'),
  double textScale = 1.0,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('ar'), Locale('ur')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: home,
  );
}

Widget routedApp(Widget home, Locale locale) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routes: {
      '/learn/topic': (context) => LearnTopicScreen(
            topic: ModalRoute.of(context)!.settings.arguments! as LearnTopic,
          ),
    },
    home: home,
  );
}

bool _adaptersRegistered = false;

Future<void> openBoxes() async {
  final dir = Directory.systemTemp.createTempSync('floii_learn_test');
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

/// Home needs the real localization delegate for its tooltips.
Widget homeApp(
  Widget home, {
  Map<String, WidgetBuilder>? routes,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: const [Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routes: routes ?? const {},
    home: home,
  );
}

void setPhoneSize(WidgetTester tester, Size logical) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = logical;
  addTearDown(tester.view.reset);
}

void main() {
  group('learn content', () {
    test('every catalogue entry has an English article', () {
      for (final topic in learnTopics) {
        final article = LearnContent.of(topic.id, 'en');
        expect(article, isNotNull, reason: 'missing article for ${topic.id}');
        expect(article!.title.trim(), isNotEmpty);
        expect(article.caption.trim(), isNotEmpty);
        expect(article.summary.trim(), isNotEmpty);
        expect(article.sections, isNotEmpty, reason: topic.id);

        for (final section in article.sections) {
          expect(section.heading.trim(), isNotEmpty, reason: topic.id);
          expect(section.paragraphs, isNotEmpty, reason: topic.id);
          for (final paragraph in section.paragraphs) {
            expect(paragraph.trim(), isNotEmpty, reason: topic.id);
          }
        }
        for (final fact in article.facts ?? const <LearnFact>[]) {
          expect(fact.label.trim(), isNotEmpty, reason: topic.id);
          expect(fact.value.trim(), isNotEmpty, reason: topic.id);
        }
      }
    });

    test('topic ids are unique and resolve', () {
      final ids = learnTopics.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final topic in learnTopics) {
        expect(topicById(topic.id), isNotNull);
      }
      expect(topicById('nope'), isNull);
    });

    test('untranslated languages fall back to English', () {
      // German has no catalogue yet, so the English article must be served
      // rather than an empty object.
      for (final topic in learnTopics) {
        expect(
          LearnContent.of(topic.id, 'de')?.title,
          LearnContent.of(topic.id, 'en')?.title,
          reason: topic.id,
        );
      }
    });

    test('unknown topic id resolves to nothing', () {
      expect(LearnContent.of('nope', 'en'), isNull);
    });
  });

  group('learn page', () {
    testWidgets('lists every topic with its title and caption', (tester) async {
      // Tall enough that the whole lazy list is built.
      setPhoneSize(tester, const Size(390, 2400));
      await tester.pumpWidget(app(const LearnScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.text('learn'), findsOneWidget);
      for (final topic in learnTopics) {
        expect(find.text(topic.id), findsNothing);
        expect(
          find.text(LearnContent.of(topic.id, 'en')!.title),
          findsOneWidget,
          reason: topic.id,
        );
      }
      expect(find.byIcon(Icons.chevron_right_rounded),
          findsNWidgets(learnTopics.length));
    });

    testWidgets('topic rows are spacers, not cards', (tester) async {
      setPhoneSize(tester, const Size(390, 2400));
      await tester.pumpWidget(app(const LearnScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // The list used to be a stack of ClayCards; it is now plain rows on the
      // page background, so no card should remain on the index.
      expect(find.byType(ClayCard), findsNothing);

      // Every row is still individually tappable.
      expect(
        find.byType(InkWell),
        findsNWidgets(learnTopics.length),
      );
    });

    testWidgets('app bar is 70 tall on both learn screens', (tester) async {
      setPhoneSize(tester, const Size(390, 844));

      await tester.pumpWidget(app(const LearnScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      _expectAppBarHeight(tester, 70);

      await tester.pumpWidget(app(LearnTopicScreen(topic: _phasesTopic)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      _expectAppBarHeight(tester, 70);
    });

    testWidgets('renders bold, italic and highlighted runs', (tester) async {
      setPhoneSize(tester, const Size(390, 2400));
      await tester.pumpWidget(
        app(LearnTopicScreen(topic: _basicsTopic)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // The basics article uses all three styles, so all three must be rendered
      // as styled spans rather than literal asterisks or exclamation marks.
      final runs = _styledRuns(tester).toList();

      expect(
        runs.where((s) => s.fontWeight?.value == 700),
        isNotEmpty,
        reason: 'no bold runs rendered',
      );
      expect(
        runs.where((s) => s.fontStyle == FontStyle.italic),
        isNotEmpty,
        reason: 'no italic runs rendered',
      );
      expect(
        runs.where((s) => s.backgroundColor != null),
        isNotEmpty,
        reason: 'no highlighted runs rendered',
      );

      // Markers must not leak into the rendered text.
      final summary = LearnContent.of('basics', 'en')!.summary;
      expect(summary, contains('**'));
      expect(
        find.text(_stripped(summary), findRichText: true),
        findsOneWidget,
        reason: 'markers were rendered literally instead of styled',
      );
      // The highlighted and italic runs live in the body, further down.
      expect(
        find.textContaining('!!', findRichText: true),
        findsNothing,
        reason: 'an !! marker was printed to the reader',
      );
      expect(
        find.textContaining('**', findRichText: true),
        findsNothing,
        reason: 'a ** marker was printed to the reader',
      );
    });

    testWidgets('markup in every article is balanced', (tester) async {
      for (final topic in learnTopics) {
        final article = LearnContent.of(topic.id, 'en')!;
        for (final text in [
          article.title,
          article.caption,
          article.summary,
          ...article.facts!.map((f) => '${f.label} ${f.value}'),
          for (final s in article.sections) ...[
            s.heading,
            ...s.paragraphs,
          ],
        ]) {
          expect(_balanced(text, r'\*\*'), isTrue, reason: '** in: $text');
          expect(_balanced(text, '!!'), isTrue, reason: '!! in: $text');
        }
      }
    });

    testWidgets('tapping a topic opens the article', (tester) async {
      setPhoneSize(tester, const Size(390, 844));
      await tester.pumpWidget(routedApp(const LearnScreen(), Locale('en')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final article = LearnContent.of('phases', 'en')!;
      await tester.tap(find.text(article.title));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.byType(LearnTopicScreen), findsOneWidget);
      // The summary and the first section heading are both on screen.
      expect(
        find.text(_stripped(article.summary), findRichText: true),
        findsOneWidget,
      );
      expect(find.text(article.sections.first.heading), findsOneWidget);
    });

    testWidgets('renders the key facts as one bold label and italic value',
        (tester) async {
      setPhoneSize(tester, const Size(390, 2400));
      await tester.pumpWidget(
        app(LearnTopicScreen(topic: _phasesTopic)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final facts = LearnContent.of('phases', 'en')!.facts!;
      expect(facts, isNotEmpty);
      for (final fact in facts) {
        // Each row is one 'label: value' line, not two stacked lines.
        final row =
            find.text('${fact.label}: ${fact.value}', findRichText: true);
        expect(
          row,
          findsOneWidget,
          reason: 'fact row not found: ${fact.label}',
        );

        // Text.rich normalises the span it renders, so read the style off the
        // Text widget's own textSpan instead of the built RichText.
        final target = '${fact.label}: ${fact.value}';
        final span = tester
            .widgetList<Text>(find.byType(Text))
            .map((w) => w.textSpan)
            .whereType<TextSpan>()
            .firstWhere((sp) => sp.toPlainText() == target);
        final spanChildren = span.children!.cast<TextSpan>();
        expect(spanChildren.first.style?.fontWeight, FontWeight.w700,
            reason: 'label is not bold: ${fact.label}');
        expect(spanChildren.last.style?.fontStyle, FontStyle.italic,
            reason: 'value is not italic: ${fact.label}');
      }
      // Labels must not repeat a section heading on the same page.
      final headings = LearnContent.of('phases', 'en')!
          .sections
          .map((s) => s.heading)
          .toSet();
      for (final fact in facts) {
        expect(headings, isNot(contains(fact.label)), reason: fact.label);
      }
    });

    testWidgets('quick info is a titled accordion', (tester) async {
      setPhoneSize(tester, const Size(390, 2400));
      await tester.pumpWidget(
        app(LearnTopicScreen(topic: _phasesTopic)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.text('learnQuickInfo'), findsOneWidget);

      // The header carries an info icon rather than a bolt, which read as
      // "fast" rather than "quick reference".
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsNothing);

      final firstFact = LearnContent.of('phases', 'en')!.facts!.first;
      final factRow = find.text('${firstFact.label}: ${firstFact.value}',
          findRichText: true);

      // Open by default, then collapsed by tapping the header.
      expect(factRow, findsOneWidget);

      await tester.tap(find.text('learnQuickInfo'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(factRow, findsNothing, reason: 'accordion did not collapse');

      await tester.tap(find.text('learnQuickInfo'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(factRow, findsOneWidget, reason: 'accordion did not reopen');
    });

    testWidgets('summary reads as a section, not a card', (tester) async {
      setPhoneSize(tester, const Size(390, 2400));
      await tester.pumpWidget(
        app(LearnTopicScreen(topic: _phasesTopic)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // The opening summary gets a heading like every other section.
      expect(find.text('learnInShort'), findsOneWidget);

      // Only the Quick Info panel is a card now.
      expect(find.byType(ClayCard), findsOneWidget);
    });

    testWidgets('article survives a small phone with large system text',
        (tester) async {
      setPhoneSize(tester, const Size(320, 640));
      await tester.pumpWidget(
        app(LearnTopicScreen(topic: _basicsTopic), textScale: 1.6),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('topic list survives a small phone with large system text',
        (tester) async {
      setPhoneSize(tester, const Size(320, 640));
      await tester.pumpWidget(app(const LearnScreen(), textScale: 1.6));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('missing article falls back to a placeholder page',
        (tester) async {
      await tester.pumpWidget(
        app(LearnTopicScreen(topic: _unknownTopic)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('learnUnavailable'), findsOneWidget);
    });

    testWidgets('home app bar action opens the learn page', (tester) async {
      await tester.runAsync(openBoxes);
      addTearDown(() async => Hive.close());
      setPhoneSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        homeApp(
          HomeScreen(stats: dashboardStats()),
          routes: {'/learn': (context) => const LearnScreen()},
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Learn'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.byType(LearnScreen), findsOneWidget);
      expect(
        find.text(LearnContent.of('basics', 'en')!.title),
        findsOneWidget,
      );
    });

    testWidgets('RTL locale still renders the article', (tester) async {
      await tester.pumpWidget(
        app(LearnTopicScreen(topic: _basicsTopic), locale: Locale('ar')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.text(
          _stripped(LearnContent.of('basics', 'en')!.summary),
          findRichText: true,
        ),
        findsOneWidget,
      );
    });
  });
}

final _basicsTopic = topicById('basics')!;
final _phasesTopic = topicById('phases')!;
final _unknownTopic = const LearnTopic(
  id: 'nope',
  icon: Icons.help_outline,
  color: AppColors.secondary,
);
