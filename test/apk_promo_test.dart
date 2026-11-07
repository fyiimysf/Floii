import 'package:floi/services/localization/app_localizations.dart';
import 'package:floi/widgets/common/download_apk_banner.dart';
import 'package:floi/widgets/common/download_apk_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hosts [child] the way the app does for a given locale, so the promo widgets
/// get real translations instead of falling back to raw keys.
Widget _host(Widget child, Locale locale) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('de')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final locale in const [Locale('en'), Locale('de')]) {
    for (final size in const [Size(320, 640), Size(390, 844)]) {
      final tag = '${locale.languageCode}@${size.width.toInt()}';

      testWidgets('download banner has no overflow $tag', (tester) async {
        _setSize(tester, size);
        await tester.pumpWidget(
          _host(
            const Column(children: [DownloadApkBanner()]),
            locale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('download card has no overflow $tag', (tester) async {
        _setSize(tester, size);
        await tester.pumpWidget(
          _host(
            const SingleChildScrollView(
              padding: EdgeInsets.all(12),
              child: DownloadApkCard(),
            ),
            locale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
