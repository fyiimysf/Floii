import 'package:flutter/cupertino.dart' show CupertinoPageTransition;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floi/theme/app_theme.dart';

Widget _app({
  Brightness brightness = Brightness.light,
  required void Function(BuildContext) onPush,
}) =>
    MaterialApp(
      theme: brightness == Brightness.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => onPush(context),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );

Future<void> _pushSecond(WidgetTester tester) async {
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
}

void main() {
  test('every platform shares the same slide-back transition', () {
    final builders = AppTheme.lightTheme.pageTransitionsTheme.builders;
    expect(builders.keys.toSet(), TargetPlatform.values.toSet());

    expect(builders.values.map((b) => b.runtimeType).toSet().length, 1,
        reason: 'some platform would fall back to the zooming default');

    // The iOS slide lasts 500ms; the shared builder must drive that too.
    expect(
      builders[TargetPlatform.android]!.transitionDuration,
      const Duration(milliseconds: 500),
    );

    // Dark mode must not quietly get a different push.
    final dark = AppTheme
        .darkTheme.pageTransitionsTheme.builders[TargetPlatform.android];
    expect(dark.runtimeType, builders[TargetPlatform.android]!.runtimeType);
  });

  testWidgets('a pushed page slides in horizontally from the trailing edge',
      (tester) async {
    await tester.pumpWidget(_app(
      onPush: (context) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('second')),
        ),
      ),
    ));

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Mid-flight the incoming page is still out past the trailing edge.
    final slides = find.ancestor(
      of: find.text('second'),
      matching: find.byType(SlideTransition),
    );
    expect(slides, findsWidgets);
    expect(
      tester.widget<SlideTransition>(slides.first).position.value.dx,
      greaterThan(0),
    );

    await tester.pumpAndSettle();
    expect(find.text('second'), findsOneWidget);
    expect(
      tester.widget<SlideTransition>(slides.first).position.value,
      Offset.zero,
    );
  });

  testWidgets('reduced motion hands the page straight through', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(_app(
      onPush: (context) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('second')),
        ),
      ),
    ));
    await _pushSecond(tester);

    expect(find.text('second'), findsOneWidget);
    expect(find.byType(CupertinoPageTransition), findsNothing);
  });

  testWidgets('the dark theme slides in the same way', (tester) async {
    await tester.pumpWidget(_app(
      brightness: Brightness.dark,
      onPush: (context) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('second')),
        ),
      ),
    ));
    await _pushSecond(tester);

    expect(find.byType(CupertinoPageTransition), findsOneWidget);
    expect(find.text('second'), findsOneWidget);
  });

  testWidgets('an edge drag follows the finger and then pops the page',
      (tester) async {
    await tester.pumpWidget(_app(
      onPush: (context) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('second')),
        ),
      ),
    ));
    await _pushSecond(tester);

    final gesture = await tester.startGesture(const Offset(5, 300));
    await tester.pump();
    await gesture.moveBy(const Offset(200, 0));
    await tester.pump();

    // The page is still on screen and has moved with the drag, not on a timer.
    expect(find.text('second'), findsOneWidget);
    final dragging = find.ancestor(
      of: find.text('second'),
      matching: find.byType(SlideTransition),
    );
    expect(
      tester.widget<SlideTransition>(dragging.first).position.value.dx,
      greaterThan(0),
    );

    await gesture.moveBy(const Offset(400, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    // Dragged well past halfway, so the page popped back off.
    expect(find.text('second'), findsNothing);
  });
}
