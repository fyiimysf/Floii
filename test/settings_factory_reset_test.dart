import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:floi/models/cycle_models.dart';
import 'package:floi/screens/settings/settings_screen.dart';
import 'package:floi/services/localization/app_localizations.dart';
import 'package:floi/widgets/common/hold_to_confirm.dart';

const _hold = Duration(milliseconds: 1200);

bool _adaptersRegistered = false;

Future<void> openBoxes() async {
  final dir = Directory.systemTemp.createTempSync('floii_settings_test');
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

/// Route names the app actually asked for. `home` bypasses `onGenerateRoute`,
/// so only explicit `pushNamed` calls land here.
final pushedRoutes = <String?>[];

Widget app() => MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [AppLocalizations.delegate],
      onGenerateRoute: (settings) {
        pushedRoutes.add(settings.name);
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(body: Text(settings.name ?? 'unknown')),
        );
      },
      home: const SettingsScreen(),
    );

/// Presses and holds for [total], stepping the clock so the ticker advances.
Future<void> holdFor(WidgetTester tester, Finder finder, Duration total) async {
  final gesture = await tester.startGesture(tester.getCenter(finder));
  await tester.pump();
  var elapsed = Duration.zero;
  while (elapsed < total) {
    final step = (total - elapsed) < const Duration(milliseconds: 50)
        ? total - elapsed
        : const Duration(milliseconds: 50);
    await tester.pump(step);
    elapsed += step;
  }
  // Completion lands one frame past the duration boundary.
  await tester.pump(const Duration(milliseconds: 16));
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  // Opened once for the whole file and deliberately never closed: the reset
  // clears the boxes and leaves a disk write in flight, and `Hive.close` waits
  // on it forever. Each test file gets its own process, so leaving them open is
  // harmless.
  setUpAll(openBoxes);

  setUp(() {
    pushedRoutes.clear();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Hold to Delete Data'), 200);
    await tester.pumpAndSettle();
  }

  testWidgets('the tile itself reads as a hold', (tester) async {
    await pumpSettings(tester);

    // The instruction is the title, not a subtitle, so the whole row reads as
    // one command.
    final title = tester.widget<Text>(
      find.descendant(
        of: find.byType(HoldToConfirm).last,
        matching: find.text('Hold to Delete Data'),
      ),
    );
    expect(title.data, 'Hold to Delete Data');
    expect(find.text('Factory Reset'), findsNothing);

    // The title says how, so the subtext has to say what is being destroyed.
    expect(
        find.text('Erases everything and restarts onboarding'), findsOneWidget,
        reason: 'the consequence of the hold is not spelled out');
  });

  testWidgets('factory reset demands a 1200ms hold', (tester) async {
    await pumpSettings(tester);

    final holder =
        tester.widget<HoldToConfirm>(find.byType(HoldToConfirm).last);
    expect(holder.duration, _hold,
        reason: 'a destructive action should not be one careless swipe away');

    // The tile itself must not also react to an ordinary tap, otherwise a
    // stray touch could delete without the hold.
    final tile = tester.widget<ListTile>(find.descendant(
      of: find.byType(HoldToConfirm).last,
      matching: find.byType(ListTile),
    ));
    expect(tile.onTap, isNull, reason: 'the tile still has a tap handler');

    // A tap must do nothing at all: the old dialog opener is gone.
    await tester.tap(find.text('Hold to Delete Data'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(Dialog), findsNothing);

    // Neither must a hold that stops short. Assert the bar actually moved
    // first, so this cannot pass by missing the tile entirely.
    await holdFor(tester, find.text('Hold to Delete Data'),
        const Duration(milliseconds: 1000));
    expect(
      tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox).last)
          .widthFactor,
      0,
      reason: 'the bar should have reset once the finger lifted',
    );

    expect(find.byType(AlertDialog), findsNothing,
        reason: 'a 1000ms hold popped a confirmation dialog');
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget,
        reason: 'a short hold navigated away and deleted everything');
    expect(pushedRoutes, isEmpty);
  });

  testWidgets('a completed hold clears the data and opens onboarding',
      (tester) async {
    await pumpSettings(tester);

    await holdFor(tester, find.text('Hold to Delete Data'), _hold);
    // The snackbar is shown before leaving, so let the delay elapse.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(pushedRoutes, ['/onboarding'],
        reason: 'the reset must land on onboarding, not the old home shell');
    expect(find.text('/onboarding'), findsOneWidget,
        reason: 'the settings screen is still on top');
    // Offstage routes are not built, so look at the stack depth: settings must
    // be gone rather than merely hidden underneath onboarding.
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    expect(nav.canPop(), isFalse,
        reason: 'settings is still in the stack, so Back returns to it');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('has_completed_onboarding'), isFalse,
        reason: 'onboarding would be skipped on the next launch');
  });

  testWidgets('a completed hold leaves no full bar behind', (tester) async {
    await pumpSettings(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Hold to Delete Data')),
    );
    await tester.pump();
    for (var i = 0; i < 26; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final bar = find.byType(FractionallySizedBox);
    expect(tester.widget<FractionallySizedBox>(bar.last).widthFactor, 1,
        reason: 'the bar should be full at the moment of completion');

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<FractionallySizedBox>(bar.last).widthFactor, 0,
        reason: 'the bar stayed painted after the finger lifted');

    // Let the reset's delayed navigation run so no timer outlives the test.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
  });
}
