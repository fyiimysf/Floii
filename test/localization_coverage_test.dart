import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floi/services/localization/app_localizations.dart';

/// Locales the app ships translations for, matching the `supportedLocales`
/// list in `lib/app.dart` and `isSupported` in the localization delegate.
const supportedLanguages = ['en', 'ar', 'ur', 'id', 'de'];

/// Every literal translation key referenced from `lib/`.
///
/// Interpolated lookups such as `mood_${mood.name}` are deliberately skipped:
/// their keys are built at runtime and cannot be resolved by scanning source.
Set<String> keysUsedInLib() {
  final keys = <String>{};

  for (final file in Directory('lib').listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;
    // The maps themselves are the definition, not a use.
    if (file.path.endsWith('app_localizations.dart')) continue;

    final source = file.readAsStringSync();
    // Drop line comments so commented-out lookups are not counted.
    final code = source
        .split('\n')
        .map((line) =>
            line.contains('//') ? line.substring(0, line.indexOf('//')) : line)
        .join('\n');

    final lookup = RegExp(r'''\.(?:tr|trArgs)\(\s*(['"])([^'"$]+)\1''');
    for (final match in lookup.allMatches(code)) {
      keys.add(match.group(2)!);
    }
  }

  return keys;
}

void main() {
  final usedKeys = keysUsedInLib();

  test('the scan actually found keys', () {
    // Guards against the scanner silently matching nothing, which would make
    // every test below pass vacuously.
    expect(usedKeys.length, greaterThan(100));
    expect(usedKeys, contains('learn'));
  });

  test('every literal key resolves in English', () {
    final english = AppLocalizations(const Locale('en'));
    final missing = <String>[];

    for (final key in usedKeys) {
      // A key with no entry surfaces as its own raw camelCase name on screen.
      if (!english.resolves(key)) missing.add(key);
    }

    expect(
      missing,
      isEmpty,
      reason: 'These keys are used in the UI but missing from the English map, '
          'so they render as raw keys. Add them to the en block in '
          'lib/services/localization/app_localizations.dart.',
    );
  });

  test('every literal key resolves in every shipped language', () {
    for (final language in supportedLanguages) {
      final localizations = AppLocalizations(Locale(language));
      final missing = <String>[];

      for (final key in usedKeys) {
        if (!localizations.resolves(key)) missing.add(key);
      }

      expect(
        missing,
        isEmpty,
        reason: 'These keys fall back to the raw key in "$language": '
            '${missing.take(20).join(', ')}'
            '${missing.length > 20 ? ' and ${missing.length - 20} more' : ''}',
      );
    }
  });

  test('no language map is missing keys another language has', () {
    // Strict per-language presence, so a key that only survives via the
    // English fallback still counts as a gap in that language.
    final sets = {
      for (final language in supportedLanguages)
        language: {
          for (final key in usedKeys)
            if (AppLocalizations(Locale(language)).has(key)) key,
        },
    };
    final complete = sets['en']!;

    for (final language in supportedLanguages) {
      final gaps = complete.difference(sets[language]!);
      expect(
        gaps,
        isEmpty,
        reason:
            '"$language" is missing ${gaps.length} key(s) that English has: '
            '${gaps.take(20).join(', ')}'
            '${gaps.length > 20 ? ' and ${gaps.length - 20} more' : ''}',
      );
    }
  });
}
