import 'package:flutter_test/flutter_test.dart';
import 'package:floi/services/notifications/notification_service.dart';

void main() {
  final now = DateTime(2026, 9, 20, 14, 30);

  group('computePeriodWindow', () {
    test('positions the window correctly for a future prediction', () {
      final prediction = DateTime(2026, 9, 30);
      final window = NotificationService.computePeriodWindow(
        prediction: prediction,
        averageCycleLength: 28,
        periodLength: 5,
        leadDays: 3,
        now: now,
      );

      expect(window, isNotNull);
      expect(window!.predictedStart, DateTime(2026, 9, 30));
      expect(window.windowStart, DateTime(2026, 9, 27));
      expect(window.windowEnd, DateTime(2026, 10, 4));
    });

    test('keeps the prediction unchanged when its window still reaches today',
        () {
      final prediction = DateTime(2026, 9, 19);
      final window = NotificationService.computePeriodWindow(
        prediction: prediction,
        averageCycleLength: 28,
        periodLength: 5,
        leadDays: 0,
        now: now,
      );

      expect(window!.predictedStart, DateTime(2026, 9, 19));
      expect(window.windowEnd, DateTime(2026, 9, 23));
    });

    test('projects forward one cycle when the window already ended', () {
      final prediction = DateTime(2026, 9, 10);
      final window = NotificationService.computePeriodWindow(
        prediction: prediction,
        averageCycleLength: 28,
        periodLength: 5,
        leadDays: 3,
        now: now,
      );

      expect(window!.predictedStart, DateTime(2026, 10, 8));
      expect(window.windowStart, DateTime(2026, 10, 5));
      expect(window.windowEnd, DateTime(2026, 10, 12));
    });

    test('projects forward multiple cycles for stale predictions', () {
      final prediction = DateTime(2026, 7, 22);
      final window = NotificationService.computePeriodWindow(
        prediction: prediction,
        averageCycleLength: 28,
        periodLength: 5,
        leadDays: 3,
        now: now,
      );

      expect(window!.predictedStart, DateTime(2026, 9, 16));
      expect(window.windowStart, DateTime(2026, 9, 13));
      expect(window.windowEnd, DateTime(2026, 9, 20));
    });

    test('returns null for invalid parameters', () {
      final window = NotificationService.computePeriodWindow(
        prediction: DateTime(2026, 9, 30),
        averageCycleLength: 0,
        periodLength: 5,
        leadDays: 3,
        now: now,
      );

      expect(window, isNull);
    });
  });

  group('notification ids are disjoint', () {
    test('every reminder block occupies its own id range', () {
      final periodMax = NotificationService.periodReminderBaseId +
          NotificationService.periodReminderModulo -
          1;
      final moodMax = NotificationService.moodReminderBaseId +
          NotificationService.moodReminderModulo -
          1;
      final phaseMax = NotificationService.phaseReminderBaseId +
          NotificationService.phaseReminderModulo -
          1;

      expect(periodMax, lessThan(NotificationService.moodReminderBaseId));
      expect(moodMax, lessThan(NotificationService.ovulationReminderId));
      expect(NotificationService.ovulationReminderId,
          lessThan(NotificationService.phaseReminderBaseId));

      for (final testId in [
        NotificationService.testNotificationId,
        NotificationService.testAlarmId,
      ]) {
        expect(
            testId,
            isNot(inInclusiveRange(
                NotificationService.periodReminderBaseId, periodMax)));
        expect(
            testId,
            isNot(inInclusiveRange(
                NotificationService.moodReminderBaseId, moodMax)));
        expect(testId, isNot(NotificationService.ovulationReminderId));
        expect(
            testId,
            isNot(inInclusiveRange(
                NotificationService.phaseReminderBaseId, phaseMax)));
      }
    });
  });
}
