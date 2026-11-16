import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floi/widgets/common/top_toast.dart';

/// Pumps an app and hands back a context that sits under the root overlay.
Future<BuildContext> pumpApp(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(builder: (context) {
        ctx = context;
        return const SizedBox.expand();
      }),
    ),
  ));
  return ctx;
}

/// Shows a toast and settles its entrance animation.
Future<void> show(WidgetTester tester, BuildContext ctx, String message,
    {Duration duration = const Duration(seconds: 2)}) async {
  showTopToast(ctx, message: message, duration: duration);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  testWidgets('shows at the top of the screen, not the bottom', (tester) async {
    final ctx = await pumpApp(tester);
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    await show(tester, ctx, 'Saved');

    expect(find.text('Saved'), findsOneWidget);
    final rect = tester.getRect(find.text('Saved'));
    expect(rect.center.dy, lessThan(screenHeight / 2),
        reason: 'the toast landed in the lower half of the screen');
    expect(find.byType(SnackBar), findsNothing,
        reason: 'a bottom-anchored SnackBar was used instead');
  });

  testWidgets('clears itself after the duration', (tester) async {
    final ctx = await pumpApp(tester);

    await show(tester, ctx, 'Saved', duration: const Duration(seconds: 2));
    expect(find.text('Saved'), findsOneWidget);

    // Just short of the timeout it is still up.
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Saved'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('a second toast replaces the first', (tester) async {
    final ctx = await pumpApp(tester);

    await show(tester, ctx, 'First');
    expect(find.text('First'), findsOneWidget);

    await show(tester, ctx, 'Second');
    expect(find.text('First'), findsNothing,
        reason: 'toasts stacked instead of replacing one another');
    expect(find.text('Second'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Second'), findsNothing);
  });

  testWidgets('does not swallow taps meant for the screen below',
      (tester) async {
    var taps = 0;
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          ctx = context;
          // Directly beneath where the toast lands, so the toast really does
          // overlap it.
          return Align(
            alignment: Alignment.topCenter,
            child: ElevatedButton(
              onPressed: () => taps++,
              child: const Text('underneath'),
            ),
          );
        }),
      ),
    ));

    showTopToast(ctx, message: 'Saved');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // The toast is on top of the button, so only IgnorePointer lets the tap
    // reach it.
    expect(find.text('underneath'), findsOneWidget);
    await tester.tap(find.text('underneath'));
    expect(taps, 1, reason: 'the toast swallowed the tap');

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 250));
  });
}
