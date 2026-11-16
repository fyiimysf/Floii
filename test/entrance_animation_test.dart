import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floi/widgets/common/cards.dart';
import 'package:floi/widgets/common/entrance.dart';

Widget app(Widget child, {bool reduceMotion = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: Center(child: child)),
      ),
    );

/// The entrance wraps the card, so its Opacity and Transform sit above the
/// label rather than below it.
double opacityOf(WidgetTester tester, Finder finder) => tester
    .widget<Opacity>(find
        .ancestor(
          of: finder,
          matching: find.byType(Opacity),
        )
        .first)
    .opacity;

/// Whether an entrance wrapper was inserted above [label] at all. With reduced
/// motion there is deliberately no wrapper: nothing to animate, nothing to wait
/// on.
bool hasEntranceWrapper(WidgetTester tester, Finder label) => find
    .ancestor(of: label, matching: find.byType(Opacity))
    .evaluate()
    .isNotEmpty;

double offsetOf(WidgetTester tester, Finder finder) {
  final transform = tester.widget<Transform>(
      find.ancestor(of: finder, matching: find.byType(Transform)).first);
  return transform.transform.getTranslation().y;
}

void main() {
  testWidgets('a card starts transparent and offset, then settles',
      (tester) async {
    await tester
        .pumpWidget(app(const ClayCard(entranceStep: 0, child: Text('hello'))));

    expect(opacityOf(tester, find.text('hello')), 0,
        reason: 'the card should not appear fully faded in');
    expect(offsetOf(tester, find.text('hello')), greaterThan(0),
        reason: 'the card should start below its resting place');

    await tester.pump(const Duration(milliseconds: 170));
    final mid = opacityOf(tester, find.text('hello'));
    expect(mid, greaterThan(0));
    expect(mid, lessThan(1), reason: 'it should still be arriving');

    await tester.pumpAndSettle();
    expect(opacityOf(tester, find.text('hello')), 1);
    expect(offsetOf(tester, find.text('hello')), 0);
  });

  testWidgets('a rebuild does not replay the animation', (tester) async {
    // The screens rebuild on every Hive write; the entrance must not re-run.
    Widget build(String label) => app(
          ClayCard(entranceStep: 0, child: Text(label)),
        );

    await tester.pumpWidget(build('first'));
    await tester.pumpAndSettle();
    expect(opacityOf(tester, find.text('first')), 1);

    await tester.pumpWidget(build('second'));
    await tester.pump();
    expect(opacityOf(tester, find.text('second')), 1,
        reason: 'the entrance replayed on rebuild');
  });

  testWidgets('a card with no entranceStep stays completely still',
      (tester) async {
    // Screens the user left out of the motion pass must not animate.
    await tester.pumpWidget(app(const ClayCard(child: Text('quiet'))));

    expect(hasEntranceWrapper(tester, find.text('quiet')), isFalse,
        reason: 'a card animated without being opted in');
    await tester.pump(const Duration(milliseconds: 200));
    expect(hasEntranceWrapper(tester, find.text('quiet')), isFalse);
  });

  testWidgets('entranceStep turns a beat into a delay', (tester) async {
    await tester
        .pumpWidget(app(const ClayCard(entranceStep: 3, child: Text('late'))));

    // Three beats of ClayCard.stagger.
    await tester.pump(ClayCard.stagger * 2);
    expect(opacityOf(tester, find.text('late')), 0,
        reason: 'the card started before its beat came around');

    await tester.pump(ClayCard.stagger);
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacityOf(tester, find.text('late')), greaterThan(0));

    await tester.pumpAndSettle();
    expect(opacityOf(tester, find.text('late')), 1);
  });

  testWidgets('reduce motion skips the animation entirely', (tester) async {
    await tester.pumpWidget(app(
        const ClayCard(entranceStep: 0, child: Text('hello')),
        reduceMotion: true));

    // No wrapper at all, so there is no animation to wait on and the card is
    // simply there from the first frame.
    expect(hasEntranceWrapper(tester, find.text('hello')), isFalse,
        reason: 'an animated wrapper was built despite reduced motion');
    expect(find.text('hello'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0,
        reason: 'a ticker was left running even though nothing moves');

    await tester.pumpAndSettle();
    expect(hasEntranceWrapper(tester, find.text('hello')), isFalse);
    expect(tester.binding.transientCallbackCount, 0,
        reason: 'the entrance kept animating after it should have stopped');
  });

  testWidgets('StaggeredColumn delays each child in turn', (tester) async {
    await tester.pumpWidget(app(const StaggeredColumn(
      stagger: Duration(milliseconds: 100),
      children: [Text('one'), Text('two'), Text('three')],
    )));

    final atStart = <double>[
      opacityOf(tester, find.text('one')),
      opacityOf(tester, find.text('two')),
      opacityOf(tester, find.text('three')),
    ];
    expect(atStart.every((o) => o == 0), isTrue,
        reason: 'nothing should have started yet');

    await tester.pump(const Duration(milliseconds: 120));
    expect(opacityOf(tester, find.text('one')), greaterThan(0),
        reason: 'the first child never started');
    expect(opacityOf(tester, find.text('two')), 0,
        reason: 'the second child started too early');

    await tester.pump(const Duration(milliseconds: 100));
    expect(opacityOf(tester, find.text('two')), greaterThan(0),
        reason: 'the second child never started');

    await tester.pump(const Duration(milliseconds: 100));
    expect(opacityOf(tester, find.text('three')), greaterThan(0),
        reason: 'the third child never started');

    await tester.pumpAndSettle();
    for (final label in ['one', 'two', 'three']) {
      expect(opacityOf(tester, find.text(label)), 1);
    }
  });

  testWidgets('StaggeredColumn collapses the stagger when motion is reduced',
      (tester) async {
    await tester.pumpWidget(app(
      const StaggeredColumn(
        children: [Text('one'), Text('two')],
      ),
      reduceMotion: true,
    ));

    await tester.pumpAndSettle();
    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
    expect(hasEntranceWrapper(tester, find.text('one')), isFalse);
    expect(hasEntranceWrapper(tester, find.text('two')), isFalse,
        reason: 'the stagger was not collapsed for reduced motion');
  });
}
