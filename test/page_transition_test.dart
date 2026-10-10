import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floi/theme/app_theme.dart';

/// Minimal stand-in for the route a transition builder is handed.
class _FakeRoute<T> extends PageRoute<T> {
  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      const SizedBox.shrink();
}

/// Hosts the built transition directly. Deliberately no MaterialApp: its own
/// route would add a transition of its own and the finds would pass for the
/// wrong reason.
Widget _host(Widget Function(BuildContext) build,
        {bool reduceMotion = false}) =>
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(builder: build),
      ),
    );

const _page = SizedBox(key: Key('page'));

void main() {
  PageTransitionsBuilder builderFor(Brightness brightness) =>
      (brightness == Brightness.dark ? AppTheme.darkTheme : AppTheme.lightTheme)
          .pageTransitionsTheme
          .builders[TargetPlatform.android]!;

  test('every platform shares the same push transition', () {
    final builders = AppTheme.lightTheme.pageTransitionsTheme.builders;
    expect(builders.keys.toSet(), TargetPlatform.values.toSet());

    expect(builders.values.map((b) => b.runtimeType).toSet().length, 1,
        reason: 'some platform would fall back to the zooming default');

    // Dark mode must not quietly get a different push.
    final dark = AppTheme
        .darkTheme.pageTransitionsTheme.builders[TargetPlatform.android];
    expect(dark.runtimeType, builders[TargetPlatform.android]!.runtimeType);
  });

  testWidgets('a pushed page fades in while it rises', (tester) async {
    final controller = AnimationController(
      vsync: tester,
      duration: const Duration(milliseconds: 300),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(
      (context) => builderFor(Brightness.light).buildTransitions(
        _FakeRoute<void>(),
        context,
        controller,
        const AlwaysStoppedAnimation<double>(0),
        _page,
      ),
    ));

    expect(find.byType(FadeTransition), findsOneWidget);
    expect(find.byType(SlideTransition), findsOneWidget);
    expect(find.byKey(const Key('page')), findsOneWidget);

    // At the start the page is offset and invisible.
    controller.value = 0;
    await tester.pump();
    expect(
      tester.widget<FadeTransition>(find.byType(FadeTransition)).opacity.value,
      0,
    );
    expect(
      tester
          .widget<SlideTransition>(find.byType(SlideTransition))
          .position
          .value,
      const Offset(0, 0.04),
    );

    // Once it has arrived it is fully opaque and back in place.
    controller.value = 1;
    await tester.pump();
    expect(
      tester.widget<FadeTransition>(find.byType(FadeTransition)).opacity.value,
      1,
    );
    expect(
      tester
          .widget<SlideTransition>(find.byType(SlideTransition))
          .position
          .value,
      Offset.zero,
    );
  });

  testWidgets('a pushed page does not animate when motion is reduced',
      (tester) async {
    final controller = AnimationController(
      vsync: tester,
      duration: const Duration(milliseconds: 300),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(
      (context) => builderFor(Brightness.light).buildTransitions(
        _FakeRoute<void>(),
        context,
        controller,
        const AlwaysStoppedAnimation<double>(0),
        _page,
      ),
      reduceMotion: true,
    ));

    // The page is handed straight through, with no transition widgets at all.
    expect(find.byType(FadeTransition), findsNothing);
    expect(find.byType(SlideTransition), findsNothing);
    expect(find.byKey(const Key('page')), findsOneWidget);
  });

  testWidgets('the dark theme pushes with the same fade and rise',
      (tester) async {
    final controller = AnimationController(
      vsync: tester,
      duration: const Duration(milliseconds: 300),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(
      (context) => builderFor(Brightness.dark).buildTransitions(
        _FakeRoute<void>(),
        context,
        controller,
        const AlwaysStoppedAnimation<double>(0),
        _page,
      ),
    ));

    controller.value = 0;
    await tester.pump();
    expect(
      tester.widget<FadeTransition>(find.byType(FadeTransition)).opacity.value,
      0,
    );
    expect(
      tester
          .widget<SlideTransition>(find.byType(SlideTransition))
          .position
          .value,
      const Offset(0, 0.04),
    );
  });
}
