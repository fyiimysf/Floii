import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:floi/models/cycle_models.dart';
import 'package:floi/screens/home/widgets/calendar_widget.dart';

Map<String, dynamic> emptyStats() => {
      'periods': <List<DateTime>>[],
      'average': 28,
      'currentPeriodLength': 5,
    };

Map<String, dynamic>? _stats;

class _Harness extends StatefulWidget {
  final DateTime initialMonth;
  final ValueChanged<int> onPageChanged;
  const _Harness({required this.initialMonth, required this.onPageChanged});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late DateTime _currentMonth;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialMonth;
    _controller = PageController(initialPage: monthPageIndex(_currentMonth));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToToday() {
    final target = monthPageIndex(DateTime.now());
    final current = _controller.hasClients
        ? (_controller.page?.round() ?? monthPageIndex(_currentMonth))
        : monthPageIndex(_currentMonth);
    if ((target - current).abs() > 6) {
      _controller.jumpToPage(target);
    } else {
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 400),
        curve: const Cubic(0.34, 1.56, 0.64, 1.0),
      );
    }
    setState(() {
      _currentMonth = DateTime.now();
    });
  }

  void _onPageChanged(int index) {
    widget.onPageChanged(index);
    setState(() {
      _currentMonth = monthFromPageIndex(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(onPressed: _goToToday, child: const Text('TODAY')),
          Expanded(
            child: CalendarWidget(
              currentMonth: _currentMonth,
              predictedPeriods: <DateTime>[],
              stats: _stats!,
              pageController: _controller,
              onPageChanged: _onPageChanged,
              onDateTap: (_, __) {},
              onDateLongPress: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('today_sync_test');
    Hive.init(tempDir.path);
    Hive.registerAdapter(DailyDataAdapter());
    await Hive.openBox<DailyData>('dailyData');
    _stats = emptyStats();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('today returns to today from 5 years ahead', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);

    final todayIndex = monthPageIndex(DateTime.now());
    final farMonth = DateTime(DateTime.now().year + 5, DateTime.now().month, 1);

    final changed = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: _Harness(
          initialMonth: farMonth,
          onPageChanged: changed.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('TODAY'));
    await tester.pumpAndSettle();

    final controller =
        tester.state<_HarnessState>(find.byType(_Harness))._controller;
    expect(controller.page?.round(), todayIndex,
        reason: 'title should settle on today');
    expect(changed.last, todayIndex, reason: 'last change should be today');
    expect(tester.takeException(), isNull);
  });
}
