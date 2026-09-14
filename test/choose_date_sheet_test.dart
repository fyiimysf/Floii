import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' as intl;

import 'package:floi/screens/home/dialogs/choose_date_sheet.dart';
import 'package:floi/services/localization/app_localizations.dart';
import 'package:floi/utils/extensions/date_extensions.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    DateTime? initial,
    required void Function(DateTime, int) onSave,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: ChooseDateSheet(
            initialDate: initial ?? DateTime.now(),
            defaultMenstrualDays: 5,
            onSave: onSave,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String rangeLabel(DateTime start, int days) {
    return '${intl.DateFormat('MMM dd').format(start)} - '
        '${intl.DateFormat('MMM dd').format(start.addDays(days - 1))}';
  }

  testWidgets('shows an infinite date wheel centered on the start date',
      (tester) async {
    final now = DateTime.now();
    await pumpSheet(tester, onSave: (_, __) {});

    final wheel = tester.widget<ListWheelScrollView>(
      find.byType(ListWheelScrollView),
    );
    final delegate =
        wheel.childDelegate as ListWheelChildBuilderDelegate;
    expect(
      delegate.childCount!,
      greaterThan(10000),
      reason: 'the wheel must wrap over many century cycles for infinite scroll',
    );

    expect(find.text(rangeLabel(now, 5)), findsOneWidget);
    expect(
      find.text(
        '${intl.DateFormat('EEE').format(now)}, '
        '${intl.DateFormat('MMM').format(now)} ${now.year}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('scrolling the wheel changes the start date and saves it',
      (tester) async {
    final now = DateTime.now();
    DateTime? saved;
    await pumpSheet(tester, onSave: (date, days) {
      saved = date;
    });

    // Two items up the wheel -> start date moves +2 days.
    await tester.drag(
        find.byType(ListWheelScrollView), const Offset(0, -104));
    await tester.pumpAndSettle();

    final expected = now.addDays(2);
    expect(
      find.text(rangeLabel(expected, 5)),
      findsOneWidget,
      reason: 'header should follow the wheel selection',
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.isSameDate(expected), isTrue);
    expect(saved!.day, expected.day);
  });
}