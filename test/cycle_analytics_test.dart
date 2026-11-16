import 'package:flutter_test/flutter_test.dart';

import 'package:floi/services/cycle/cycle_analytics_service.dart';

void main() {
  group('CycleAnalyticsService', () {
    test('stdDev handles an int-backed list (List<int> at runtime)', () {
      final values = <int>[28, 29, 27, 30, 28];
      expect(CycleAnalyticsService.stdDev(values), closeTo(1.14, 0.01));
    });

    test('computeAnalyticsFromPeriods handles int cycle lengths', () {
      final periods = [
        [DateTime(2026, 1, 3), DateTime(2026, 1, 4)],
        [DateTime(2026, 1, 30), DateTime(2026, 1, 31)],
        [DateTime(2026, 2, 27), DateTime(2026, 2, 28)],
      ];
      final stats = CycleAnalyticsService.computeAnalyticsFromPeriods(periods);
      expect(stats['cycleStdDev'], isA<double>());
      expect(stats['averageCycle'], closeTo(27.5, 0.01));
      expect(stats['consistency'], isA<int>());
    });

    test('buildTrendsFromPeriods returns record-shaped series', () {
      final periods = [
        [DateTime(2026, 1, 3), DateTime(2026, 1, 4)],
        [DateTime(2026, 1, 30), DateTime(2026, 1, 31)],
      ];
      final trends = CycleAnalyticsService.buildTrendsFromPeriods(periods);
      final series = trends['cycleSeries'] as List<dynamic>;
      expect(series, isNotEmpty);
      expect(series.first, isA<({DateTime start, double value})>());
      expect(series.first.value, 27.0);
    });
  });
}
