import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floi/widgets/common/floating_tab_bar.dart';

Widget harness() {
  return MaterialApp(
    home: Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          FloatingTabBar(
            title: 'Home',
            accentColor: Colors.indigo,
            onAction: () {},
            actionLabel: 'Today',
            actionTooltip: 'Go to today',
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemBuilder: (context, index) => Container(
                height: 140,
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.grey.shade300,
              ),
              itemCount: 30,
            ),
          ),
        ],
      ),
    ),
  );
}

void setPhoneSize(WidgetTester tester, Size logical) {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = Size(logical.width * 3, logical.height * 3);
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('slim toolbar: no icon, title flushed left, action trailing',
      (tester) async {
    setPhoneSize(tester, const Size(412, 892));
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // No page/badge/icons anywhere in the header.
    expect(find.byIcon(Icons.home_rounded), findsNothing);
    expect(find.byType(Icon), findsNothing);

    final title = tester.getRect(find.text('Home'));
    final action = tester.getRect(find.text('Today'));

    // Title sits on the left half of the toolbar, at toolbar height.
    expect(title.center.dx, lessThan(412 / 2));
    expect(title.center.dy, lessThanOrEqualTo(56));

    // The text action trails on the right, away from the title.
    expect(action.center.dx, greaterThan(title.center.dx));
    expect(action.center.dy, lessThanOrEqualTo(56));
  });

  testWidgets('no overflow on small screen and large system font',
      (tester) async {
    setPhoneSize(tester, const Size(360, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() => tester.platformDispatcher.clearTextScaleFactorTestValue());

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(tester.getRect(find.text('Home')).height, greaterThan(0));
    expect(tester.getRect(find.text('Today')).height, greaterThan(0));
  });

  testWidgets('title sticks without overlap while scrolling past',
      (tester) async {
    setPhoneSize(tester, const Size(412, 892));
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    // Pinned toolbar stays visible with the left-aligned title.
    final title = tester.getRect(find.text('Home'));
    expect(title.center.dy, lessThanOrEqualTo(56));
    expect(title.center.dx, lessThan(412 / 2));
  });
}