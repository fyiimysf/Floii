import '../learn/learn_content_en.dart';
import '../learn/learn_content_ur.dart';
import '../learn/learn_content_ar.dart';
import '../learn/learn_content_id.dart';
import '../learn/learn_content_de.dart';
import 'learn_article.dart';

/// Registry of long-form Learn copy, one map per language.
///
/// Article prose lives here rather than in `AppLocalizations` because it is
/// reference text rather than interface strings, and because the volume grows
/// quickly with each language. Lookup falls back to English, so a partially
/// translated catalogue shows English prose rather than raw keys.
///
/// English is currently the only catalogue, so `ar`, `ur`, `id` and `de` render
/// the English articles behind their own localized interface. To add a
/// language:
///
///  1. Copy `learn_content_en.dart` to `learn_content_<code>.dart`, rename
///     `learnArticlesEn` to `learnArticles<code>`, and translate the strings.
///     The map shape must stay identical: every key in `LearnTopic.all`
///     present, each with the same number of facts and sections.
///  2. Add the import below and register the map in `_byLanguage`.
///
/// `test/learn_content_integrity_test.dart` enforces both requirements, so an
/// incomplete or script-contaminated catalogue fails the suite instead of
/// reaching users.
class LearnContent {
  static const Map<String, Map<String, LearnArticle>> _byLanguage = {
    'en': learnArticlesEn,
    'ur': learnArticlesUr,
    'ar': learnArticlesAr,
    'id': learnArticlesId,
    'de': learnArticlesDe,
  };

  /// Article for [topicId] in [languageCode], or the English article when that
  /// language has no entry yet.
  static LearnArticle? of(String topicId, String languageCode) =>
      _byLanguage[languageCode]?[topicId] ?? _byLanguage['en']?[topicId];

  /// Languages that currently have a catalogue.
  static Iterable<String> get languages => _byLanguage.keys;

  /// Catalogue registered for [languageCode], if any.
  static Map<String, LearnArticle>? catalogueOf(String languageCode) =>
      _byLanguage[languageCode];
}
