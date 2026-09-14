import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../models/cycle_models.dart';
import '../../utils/constants/colors.dart';
import 'cycle_calculation_service.dart';

/// Rich cycle analytics: statistics, trends, and pattern findings.
///
/// All metrics derive from the same period data the rest of the app already
/// stores — no new persistence, no fabricated inputs. Every method takes
/// grouped periods (list of lists of dates) computed by
/// [CycleCalculationService] so the Insights and Trends surfaces share one
/// truth.
class CycleAnalyticsService {
  /// Median of a sorted or sortable numeric list. Never mutates input.
  static double median(List<num> values) {
    if (values.isEmpty) return 0;
    final sorted = List<num>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid].toDouble();
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }

  /// Standard deviation of a numeric list.
  static double stdDev(List<num> values) {
    if (values.length < 2) return 0;
    final nums = values.map((v) => v.toDouble()).toList();
    final mean = nums.reduce((a, b) => a + b) / nums.length;
    final variance = nums
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        (nums.length - 1);
    return math.sqrt(variance);
  }

  /// Cycle lengths between consecutive period starts.
  static List<int> cycleLengths(List<List<DateTime>> periods) {
    final lengths = <int>[];
    for (int i = 1; i < periods.length; i++) {
      lengths.add(periods[i].first.difference(periods[i - 1].first).inDays);
    }
    return lengths;
  }

  /// Duration in days of each logged period.
  static List<int> periodLengths(List<List<DateTime>> periods) {
    return periods.map((p) => p.length).toList();
  }

  /// Groups period records into lists of dates (the app's canonical period
  /// shape, `stats['periods']`).
  static List<List<DateTime>> groupPeriodsFromData(List<DailyData> allData) {
    final ranges = CycleCalculationService.groupPeriods(
        allData.where((d) => d.isPeriod).toList());
    return ranges.map(_rangeToDates).toList();
  }

  static List<DateTime> _rangeToDates(PeriodRange range) {
    final dates = <DateTime>[];
    for (var d = range.startDate;
        !d.isAfter(range.endDate);
        d = d.add(const Duration(days: 1))) {
      dates.add(d);
    }
    return dates;
  }

  /// A distilled, UI-ready statistics bundle.
  static Map<String, dynamic> computeStats(
    List<DailyData> allData, {
    int defaultCycleLength = 28,
    int defaultPeriodLength = 5,
  }) {
    return computeAnalyticsFromPeriods(groupPeriodsFromData(allData));
  }

  /// Distilled statistics from already-grouped period date lists
  /// (the shape stored in `stats['periods']`).
  static Map<String, dynamic> computeAnalyticsFromPeriods(
    List<List<DateTime>> allPeriods,
  ) {
    final cycleLengths = CycleAnalyticsService.cycleLengths(allPeriods);
    final periodLengths = CycleAnalyticsService.periodLengths(allPeriods);

    return {
      'count': allPeriods.length,
      'cycleLengths': cycleLengths,
      'periodLengths': periodLengths,
      'averageCycle': cycleLengths.isNotEmpty
          ? cycleLengths.reduce((a, b) => a + b) / cycleLengths.length
          : null,
      'medianCycle': cycleLengths.isNotEmpty ? median(cycleLengths) : null,
      'minCycle':
          cycleLengths.isNotEmpty ? cycleLengths.reduce((a, b) => a < b ? a : b) : null,
      'maxCycle':
          cycleLengths.isNotEmpty ? cycleLengths.reduce((a, b) => a > b ? a : b) : null,
      'averagePeriod': periodLengths.isNotEmpty
          ? periodLengths.reduce((a, b) => a + b) / periodLengths.length
          : null,
      'medianPeriod':
          periodLengths.isNotEmpty ? median(periodLengths) : null,
      'minPeriod':
          periodLengths.isNotEmpty ? periodLengths.reduce((a, b) => a < b ? a : b) : null,
      'maxPeriod':
          periodLengths.isNotEmpty ? periodLengths.reduce((a, b) => a > b ? a : b) : null,
      'cycleStdDev': stdDev(cycleLengths),
      'consistency': _consistencyScore(cycleLengths),
    };
  }

  /// 0–100 regularity score. 100 = every cycle identical; lower = more drift.
  static int _consistencyScore(List<int> lengths) {
    if (lengths.isEmpty) return 0;
    if (lengths.length == 1) return 100;
    final avg = lengths.reduce((a, b) => a + b) / lengths.length;
    if (avg == 0) return 0;
    final deviation = stdDev(lengths);
    final score = (100 - (deviation / avg * 100)).clamp(0, 100);
    return score.round();
  }

  /// Median cycle length for prediction (more robust than mean outliers).
  static int getPredictionCycleLength(List<DailyData> allData) {
    final periods = groupPeriodsFromData(allData);
    final lengths = cycleLengths(periods);
    if (lengths.isEmpty) return 28;
    return median(lengths).round();
  }

  /// A human-readable confidence label for the next-prediction window.
  static ({String label, Color color}) predictionConfidence(
    List<DailyData> allData,
    Map<String, dynamic> stats,
  ) {
    final consistency = stats['consistency'] as int? ??
        _consistencyScore(cycleLengths(groupPeriodsFromData(allData)));

    if (consistency >= 85) {
      return (label: 'High', color: AppColors.success);
    }
    if (consistency >= 60) {
      return (label: 'Moderate', color: AppColors.ovulation);
    }
    return (label: 'Low', color: AppColors.period);
  }

  /// Trend data for the Trends surface.
  ///
  /// Returns chronologically-ordered series: cycle lengths as (start date,
  /// span days), period lengths as (start date, duration days), plus the
  /// rolling consistency.
  static Map<String, dynamic> buildTrends(List<DailyData> allData) {
    return buildTrendsFromPeriods(groupPeriodsFromData(allData));
  }

  /// Trend data built directly from grouped period date-lists
  /// (the shape stored in `stats['periods']`).
  static Map<String, dynamic> buildTrendsFromPeriods(
    List<List<DateTime>> periods,
  ) {
    final cycleSeries = <({DateTime start, double value})>[];
    final periodSeries = <({DateTime start, double value})>[];

    for (int i = 1; i < periods.length; i++) {
      cycleSeries.add((
        start: periods[i].first,
        value: periods[i].first.difference(periods[i - 1].first).inDays.toDouble(),
      ));
    }

    for (final p in periods) {
      periodSeries.add((
        start: p.first,
        value: p.length.toDouble(),
      ));
    }

    return {
      'cycleSeries': cycleSeries,
      'periodSeries': periodSeries,
      'avgCycle': cycleSeries.isNotEmpty
          ? cycleSeries.map((e) => e.value).reduce((a, b) => a + b) /
              cycleSeries.length
          : 0,
      'avgPeriod': periodSeries.isNotEmpty
          ? periodSeries.map((e) => e.value).reduce((a, b) => a + b) /
              periodSeries.length
          : 0,
      'cycleLengths': cycleSeries.map((e) => e.value.round()).toList(),
      'periodLengths': periodSeries.map((e) => e.value.round()).toList(),
    };
  }

  /// Frequency of distinct cycle lengths (for the distribution chart).
  static List<({int length, int count, double fraction})> cycleDistribution(
    List<int> cycleLengths,
  ) {
    final map = <int, int>{};
    for (final l in cycleLengths) {
      map[l] = (map[l] ?? 0) + 1;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final total = cycleLengths.isEmpty ? 1 : cycleLengths.length;
    return entries
        .map((e) =>
            (length: e.key, count: e.value, fraction: e.value / total))
        .toList();
  }
}