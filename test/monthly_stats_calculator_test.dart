
import 'package:flutter_test/flutter_test.dart';
import 'package:hydratrack/business/calculators/monthly_stats_calculator.dart';

void main() {
  group('MonthlyStatsCalculator', () {
    group('currentMonthRange', () {
      test('March 2026: starts Mar 1, ends Mar 31', () {
        final (start, end) = MonthlyStatsCalculator.currentMonthRange(DateTime(2026, 3, 15));
        expect(start, DateTime(2026, 3, 1));
        expect(end, DateTime(2026, 3, 31));
      });
      test('December: ends Dec 31', () {
        final (_, end) = MonthlyStatsCalculator.currentMonthRange(DateTime(2026, 12, 1));
        expect(end, DateTime(2026, 12, 31));
      });
      test('February non-leap year: ends Feb 28', () {
        final (_, end) = MonthlyStatsCalculator.currentMonthRange(DateTime(2026, 2, 1));
        expect(end, DateTime(2026, 2, 28));
      });
    });

    group('compute', () {
      final start = DateTime(2026, 2, 1);
      final end   = DateTime(2026, 2, 28);

      test('empty logs: 28 days, all zeros', () {
        final stats = MonthlyStatsCalculator.compute(
          logs: [], start: start, end: end, dailyGoalOz: 64.0,
        );
        expect(stats.daily.length, 28);
        expect(stats.totalHydrationOz, 0.0);
        expect(stats.goalMetDays, 0);
      });

      test('logs outside month are ignored', () {
        final logs = [
          {'timestamp': '2026-01-31T10:00:00', 'actualHydrationOz': 100.0, 'caffeineMg': 0.0},
          {'timestamp': '2026-03-01T10:00:00', 'actualHydrationOz': 100.0, 'caffeineMg': 0.0},
        ];
        final stats = MonthlyStatsCalculator.compute(
          logs: logs, start: start, end: end, dailyGoalOz: 64.0,
        );
        expect(stats.totalHydrationOz, 0.0);
      });

      test('goal met rate: 1 day out of 28', () {
        final logs = [
          {'timestamp': '2026-02-01T10:00:00', 'actualHydrationOz': 64.0, 'caffeineMg': 0.0},
        ];
        final stats = MonthlyStatsCalculator.compute(
          logs: logs, start: start, end: end, dailyGoalOz: 64.0,
        );
        expect(stats.goalMetDays, 1);
        expect(stats.goalMetRate, closeTo(1 / 28, 0.001));
      });
    });
  });
}