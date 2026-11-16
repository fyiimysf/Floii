import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floi/widgets/common/hold_to_confirm.dart';

const _hold = Duration(milliseconds: 500);

Widget app(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

/// Presses and holds the widget, pumping frames as it goes.
///
/// The first frame after the press only stamps the controller's start time, so
/// time has to be advanced in steps: a single large `pump` elapses the clock
/// before any frame is drawn and the hold would never appear to progress.
Future<TestGesture> hold(
  WidgetTester tester,
  Finder finder, {
  Duration total = _hold,
}) async {
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
  // One frame past the target so the frame landing exactly on the duration is
  // always drawn; otherwise a hold that ends on the boundary can finish a frame
  // late. Still short of the duration for the deliberately-short cases.
  await tester.pump(const Duration(milliseconds: 16));
  return gesture;
}

void main() {
  testWidgets('does not confirm on a quick tap', (tester) async {
    var confirmed = 0;
    await tester.pumpWidget(app(HoldToConfirm(
      onConfirmed: () => confirmed++,
      child: const Text('hold me', textDirection: TextDirection.ltr),
    )));

    await tester.tap(find.text('hold me'));
    await tester.pumpAndSettle();
    expect(confirmed, 0);
  });

  testWidgets('does not confirm when released before the hold completes',
      (tester) async {
    var confirmed = 0;
    await tester.pumpWidget(app(HoldToConfirm(
      onConfirmed: () => confirmed++,
      child: const Text('hold me', textDirection: TextDirection.ltr),
    )));

    final gesture = await hold(tester, find.text('hold me'),
        total: const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(confirmed, 0, reason: 'fired after only 300ms');
  });

  testWidgets('confirms once the hold reaches the full duration',
      (tester) async {
    var confirmed = 0;
    await tester.pumpWidget(app(HoldToConfirm(
      duration: _hold,
      onConfirmed: () => confirmed++,
      child: const Text('hold me', textDirection: TextDirection.ltr),
    )));

    // 450ms is short of the 500ms needed.
    var gesture = await hold(tester, find.text('hold me'),
        total: const Duration(milliseconds: 450));
    expect(confirmed, 0, reason: 'fired before the duration elapsed');
    await gesture.up();
    await tester.pumpAndSettle();

    // A full hold does fire, and only once.
    confirmed = 0;
    gesture = await hold(tester, find.text('hold me'));
    expect(confirmed, 1);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(confirmed, 1, reason: 'a held finger fired twice');
  });

  testWidgets('progress resets when the hold is abandoned', (tester) async {
    await tester.pumpWidget(app(HoldToConfirm(
      onConfirmed: () {},
      child: const Text('hold me', textDirection: TextDirection.ltr),
    )));

    final bar = find.byType(FractionallySizedBox);
    final gesture = await hold(tester, find.text('hold me'),
        total: const Duration(milliseconds: 250));

    expect(tester.widget<FractionallySizedBox>(bar).widthFactor, greaterThan(0),
        reason: 'progress bar never started filling');

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<FractionallySizedBox>(bar).widthFactor, 0,
        reason: 'progress bar did not reset after an abandoned hold');
  });

  testWidgets('a custom duration is honoured', (tester) async {
    var confirmed = 0;
    await tester.pumpWidget(app(HoldToConfirm(
      duration: const Duration(milliseconds: 1000),
      onConfirmed: () => confirmed++,
      child: const Text('hold me', textDirection: TextDirection.ltr),
    )));

    final gesture = await hold(tester, find.text('hold me'),
        total: const Duration(milliseconds: 600));
    expect(confirmed, 0, reason: 'the 500ms default leaked into a 1000ms hold');

    await tester.pump(const Duration(milliseconds: 400));
    expect(confirmed, 1);
    await gesture.up();
  });

  testWidgets('dragging off the tile cancels the hold', (tester) async {
    var confirmed = 0;
    await tester.pumpWidget(app(HoldToConfirm(
      onConfirmed: () => confirmed++,
      child: const SizedBox(
        width: 200,
        height: 60,
        child: Center(child: Text('hold me', textDirection: TextDirection.ltr)),
      ),
    )));

    final tile = find.byType(SizedBox).first;
    expect(tester.getSize(tile), const Size(200, 60));

    final gesture = await tester.startGesture(tester.getCenter(tile));
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Slide well clear of the tile while still holding.
    await gesture.moveBy(const Offset(0, -250));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(confirmed, 0, reason: 'a hold continued after the finger left');
  });

  testWidgets('haptics accelerate while holding and stop when released',
      (tester) async {
    const total = Duration(milliseconds: 1000);
    final pulses = <Duration>[];
    final kinds = <String>[];
    var elapsed = Duration.zero;

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          pulses.add(elapsed);
          kinds.add(call.arguments.toString());
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(app(HoldToConfirm(
      duration: total,
      onConfirmed: () {},
      child: const Text('hold me', textDirection: TextDirection.ltr),
    )));

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('hold me')));
    await tester.pump();
    // Stop just short of completing so the ramp is measured on its own.
    for (var i = 0; i < 18; i++) {
      elapsed += const Duration(milliseconds: 50);
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(pulses.length, greaterThan(2), reason: 'the hold never buzzed');

    // Buzzing starts on touch-down, not after the first gap, so the button
    // acknowledges the press immediately.
    expect(pulses.first, Duration.zero,
        reason: 'the first buzz was delayed: ${pulses.first}ms');

    // The gap between pulses shrinks as the hold fills, so the back half buzzes
    // more often than the front half.
    final front = pulses.where((t) => t < const Duration(milliseconds: 450));
    final back = pulses.where((t) => t >= const Duration(milliseconds: 450));
    expect(back.length, greaterThan(front.length),
        reason: 'pulses did not accelerate');

    // A mere count comparison would also pass a uniformly fast rate, so check
    // the intervals themselves get shorter.
    final gaps = <int>[
      for (var i = 1; i < pulses.length; i++)
        (pulses[i] - pulses[i - 1]).inMilliseconds
    ];
    expect(gaps.first, greaterThan(gaps.last),
        reason: 'the buzz gap never shrank: $gaps');

    // Comparing only the endpoints is not enough: frame quantisation can make a
    // flat rate look like it shrank. The gap must never grow back mid-hold.
    for (var i = 1; i < gaps.length; i++) {
      expect(gaps[i], lessThanOrEqualTo(gaps[i - 1]),
          reason: 'the buzz gap grew back at step $i: $gaps');
    }

    // Strength steps up too, so the escalation is felt and not just heard.
    expect(kinds.first, contains('selectionClick'));
    expect(kinds.last, contains('mediumImpact'));

    // Finishing buzzes hard and silences the ramp. Completion lands one frame
    // past the duration boundary, and platform messages are delivered
    // asynchronously, so flush both before asserting.
    elapsed += const Duration(milliseconds: 100);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump();
    expect(kinds.last, contains('heavyImpact'));
    final atCompletion = kinds.length;

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 600));
    expect(kinds.length, atCompletion,
        reason: 'the device kept buzzing after the finger lifted');
  });

  testWidgets('a completed hold clears its bar and can be held again',
      (tester) async {
    var confirmed = 0;
    await tester.pumpWidget(app(HoldToConfirm(
      duration: _hold,
      onConfirmed: () => confirmed++,
      child: const Text('hold me', textDirection: TextDirection.ltr),
    )));

    final bar = find.byType(FractionallySizedBox);

    final gesture = await hold(tester, find.text('hold me'));
    expect(confirmed, 1);
    expect(tester.widget<FractionallySizedBox>(bar).widthFactor, 1,
        reason: 'the bar should be full at the moment of completion');

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<FractionallySizedBox>(bar).widthFactor, 0,
        reason: 'the bar stayed painted after the finger lifted');

    // And the tile must not be permanently latched.
    final again = await hold(tester, find.text('hold me'));
    expect(confirmed, 2, reason: 'a second hold could never fire');
    await again.up();
    await tester.pumpAndSettle();
  });

  testWidgets('buzzing stops the moment the hold is abandoned', (tester) async {
    final kinds = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          kinds.add(call.arguments.toString());
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(app(HoldToConfirm(
      duration: const Duration(milliseconds: 1000),
      onConfirmed: () {},
      child: const Text('hold me', textDirection: TextDirection.ltr),
    )));

    // Let the ramp get going, then bail out well short of the duration.
    final gesture = await hold(tester, find.text('hold me'),
        total: const Duration(milliseconds: 400));
    expect(kinds, isNotEmpty, reason: 'the hold never buzzed');

    await gesture.up();
    await tester.pumpAndSettle();
    final atRelease = kinds.length;
    expect(atRelease, isNot(contains('heavyImpact')),
        reason: 'a 400ms hold reported completion');

    // Far longer than the remaining 600ms of the hold, so any surviving timer
    // would fire several times.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(kinds.length, atRelease,
        reason: 'the device kept buzzing after the finger lifted');
  });

  testWidgets('haptics can be switched off', (tester) async {
    final kinds = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          kinds.add(call.arguments.toString());
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(app(HoldToConfirm(
      duration: const Duration(milliseconds: 300),
      haptics: false,
      onConfirmed: () {},
      child: const Text('hold me', textDirection: TextDirection.ltr),
    )));

    final gesture = await hold(tester, find.text('hold me'),
        total: const Duration(milliseconds: 300));
    expect(kinds, isEmpty, reason: 'buzzed despite haptics: false');
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
