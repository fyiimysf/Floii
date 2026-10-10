import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floi/widgets/common/entrance.dart';

void main() {
  testWidgets('a tab fades in again each time it is selected', (tester) async {
    var index = 0;

    Widget build() => MaterialApp(
          home: StatefulBuilder(builder: (context, setState) {
            return Scaffold(
              body: IndexedStack(
                index: index,
                children: [
                  for (var i = 0; i < 3; i++)
                    EntranceOnActivate(
                      isActive: index == i,
                      child: Center(child: Text('tab $i')),
                    ),
                ],
              ),
            );
          }),
        );

    // Rebuilding with a new index, as the shell does on tap.
    Future<void> select(int i) async {
      index = i;
      await tester.pumpWidget(build());
    }

    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
                of: find.text('tab 0'), matching: find.byType(Opacity)),
          )
          .opacity,
      1,
    );

    await select(1);
    await tester.pump();
    final opacity = tester
        .widget<Opacity>(find.ancestor(
            of: find.text('tab 1'), matching: find.byType(Opacity)))
        .opacity;
    expect(opacity, lessThan(1),
        reason: 'the newly selected tab snapped in with no transition');

    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
                of: find.text('tab 1'), matching: find.byType(Opacity)),
          )
          .opacity,
      1,
    );

    // Returning to a tab replays it too.
    await select(0);
    await tester.pump();
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
                of: find.text('tab 0'), matching: find.byType(Opacity)),
          )
          .opacity,
      lessThan(1),
    );
  });
}
