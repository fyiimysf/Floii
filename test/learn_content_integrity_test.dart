import 'package:flutter_test/flutter_test.dart';
import 'package:floi/content/learn/learn_article.dart';
import 'package:floi/content/learn/learn_content.dart';
import 'package:floi/models/learn_topic.dart';

/// Scripts a translated catalogue is allowed to use.
///
/// Numbers, punctuation, the Latin `mg`/`ml` unit suffixes and Latin hormone
/// names such as `PMDD` are intentionally absent: those are the exact tokens
/// that get spliced in by accident, so a catalogue has to spell them in its
/// own script or not at all.
final Map<String, List<RegExp>> allowedScripts = {
  'en': [RegExp(r'[A-Za-z]')],
  'de': [RegExp(r'[A-Za-zÀ-ÿ]')],
  'id': [RegExp(r'[A-Za-z]')],
  'ar': [RegExp(r'[؀-ۿݐ-ݿ]')],
  'ur': [RegExp(r'[؀-ۿݐ-ݿ]')],
};

/// Ranges that must never appear in any catalogue, whatever the language.
/// Han, Hangul, Kana, Cyrillic and Hebrew have no place in these articles.
final RegExp foreignScript = RegExp(
  r'[\u2E80-\u2FFF\u3040-\u30FF\u4E00-\u9FFF\uAC00-\uD7AF\u0400-\u04FF\u0590-\u05FF]',
);

Iterable<String> stringsIn(LearnArticle article) sync* {
  yield article.title;
  yield article.caption;
  yield article.summary;
  for (final fact in article.facts ?? const <LearnFact>[]) {
    yield fact.label;
    yield fact.value;
  }
  for (final section in article.sections) {
    yield section.heading;
    for (final paragraph in section.paragraphs) {
      yield paragraph;
    }
  }
}

void main() {
  final topicIds = learnTopics.map((topic) => topic.id).toList();

  test('English is always registered so lookups never return null', () {
    expect(LearnContent.languages, contains('en'));
    expect(LearnContent.catalogueOf('en'), isNotNull);
  });

  test('every registered catalogue covers every topic', () {
    expect(LearnContent.languages, isNotEmpty);
    for (final language in LearnContent.languages) {
      final catalogue = LearnContent.catalogueOf(language)!;
      for (final topicId in topicIds) {
        expect(
          catalogue.containsKey(topicId),
          isTrue,
          reason: '$language catalogue is missing "$topicId". '
              'Register a language only once all ${topicIds.length} topics '
              'are translated.',
        );
      }
    }
  });

  test('registered languages are locales the app supports', () {
    const appLocales = ['en', 'ar', 'ur', 'id', 'de'];
    for (final language in LearnContent.languages) {
      expect(
        appLocales,
        contains(language),
        reason: '"$language" is not in the app\'s supportedLocales',
      );
    }
  });

  test('catalogue shape matches English', () {
    final english = LearnContent.catalogueOf('en')!;
    for (final language in LearnContent.languages) {
      if (language == 'en') continue;
      final catalogue = LearnContent.catalogueOf(language)!;
      for (final topicId in topicIds) {
        final source = english[topicId]!;
        final translated = catalogue[topicId]!;
        expect(
          translated.sections.length,
          source.sections.length,
          reason: '$language/$topicId has a different number of sections',
        );
        expect(
          translated.facts?.length,
          source.facts?.length,
          reason: '$language/$topicId has a different number of facts',
        );
      }
    }
  });

  test('no catalogue mixes in a foreign writing system', () {
    for (final language in LearnContent.languages) {
      final catalogue = LearnContent.catalogueOf(language)!;
      for (final entry in catalogue.entries) {
        for (final text in stringsIn(entry.value)) {
          final stray = foreignScript.firstMatch(text);
          final char = stray?.group(0);
          expect(
            stray,
            isNull,
            reason: '$language/${entry.key} contains "$char" '
                '(U+${char?.runes.first.toRadixString(16).toUpperCase()}), '
                'which is not part of its script. This usually means part of '
                'the text was pasted from another language.',
          );
        }
      }
    }
  });

  test('right-to-left catalogues contain no spliced-in Latin words', () {
    // Acronyms such as PMS, FSH or LH are legitimate in Arabic and Urdu
    // medical writing, so only runs of four or more Latin letters are flagged.
    final latinWord = RegExp(r'[A-Za-zÀ-ÿ]{4,}');
    for (final language in <String>['ar', 'ur']) {
      if (!LearnContent.languages.contains(language)) continue;
      final catalogue = LearnContent.catalogueOf(language)!;
      for (final entry in catalogue.entries) {
        for (final text in stringsIn(entry.value)) {
          final word = latinWord.firstMatch(text)?.group(0);
          expect(
            word,
            isNull,
            reason: '$language/${entry.key} contains the Latin word "$word". '
                'Translate it, or keep acronyms to three letters or fewer. '
                'Found in: "$text"',
          );
        }
      }
    }
  });

  test('every catalogue uses its own script', () {
    for (final language in LearnContent.languages) {
      final allowed = allowedScripts[language];
      if (allowed == null) continue;
      final catalogue = LearnContent.catalogueOf(language)!;
      for (final entry in catalogue.entries) {
        for (final text in stringsIn(entry.value)) {
          // Digits, punctuation and spaces carry no script information.
          final letters = text.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '');
          if (letters.isEmpty) continue;
          final inScript = allowed.any((script) => script.hasMatch(text));
          expect(
            inScript,
            isTrue,
            reason: '$language/${entry.key} has no text in its own script, '
                'so it is probably untranslated English: "$text"',
          );
        }
      }
    }
  });
}
