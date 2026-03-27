
import 'package:flutter_test/flutter_test.dart';
import 'package:hydratrack/business/calculators/weekly_stats_calculator.dart';

void main() {
  group('WeeklyStatsCalculator', () {
    group('currentWeekRange', () {
      test('Wednesday returns correct Monday and Sunday', () {
        final wednesday = DateTime(2026, 3, 18); // Wednesday
        final (start, end) = WeeklyStatsCalculator.currentWeekRange(wednesday);
        expect(start, DateTime(2026, 3, 16)); // Monday
        expect(end, DateTime(2026, 3, 22));   // Sunday
      });
      test('Monday returns same day as start', () {
        final monday = DateTime(2026, 3, 16);
        final (start, _) = WeeklyStatsCalculator.currentWeekRange(monday);
        expect(start, DateTime(2026, 3, 16));
      });
    });

    group('compute', () {
      final start = DateTime(2026, 3, 16); // Monday
      final end   = DateTime(2026, 3, 22); // Sunday

      test('empty logs: all zeros, 7 days', () {
        final stats = WeeklyStatsCalculator.compute(
          logs: [], start: start, end: end, dailyGoalOz: 64.0,
        );
        expect(stats.totalHydrationOz, 0.0);
        expect(stats.totalCaffeineMg, 0.0);
        expect(stats.goalMetDays, 0);
        expect(stats.daily.length, 7);
      });

      test('one day meets goal', () {
        final logs = [
          {'timestamp': '2026-03-16T10:00:00', 'actualHydrationOz': 64.0, 'caffeineMg': 0.0},
        ];
        final stats = WeeklyStatsCalculator.compute(
          logs: logs, start: start, end: end, dailyGoalOz: 64.0,
        );
        expect(stats.goalMetDays, 1);
        expect(stats.goalMetRate, closeTo(1 / 7, 0.001));
      });

      test('logs outside week are ignored', () {
        final logs = [
          {'timestamp': '2026-03-10T10:00:00', 'actualHydrationOz': 100.0, 'caffeineMg': 50.0},
        ];
        final stats = WeeklyStatsCalculator.compute(
          logs: logs, start: start, end: end, dailyGoalOz: 64.0,
        );
        expect(stats.totalHydrationOz, 0.0);
      });

      test('multiple logs on same day are summed', () {
        final logs = [
          {'timestamp': '2026-03-16T08:00:00', 'actualHydrationOz': 30.0, 'caffeineMg': 0.0},
          {'timestamp': '2026-03-16T14:00:00', 'actualHydrationOz': 34.0, 'caffeineMg': 0.0},
        ];
        final stats = WeeklyStatsCalculator.compute(
          logs: logs, start: start, end: end, dailyGoalOz: 64.0,
        );
        expect(stats.totalHydrationOz, 64.0);
        expect(stats.goalMetDays, 1);
      });

      test('averages are correct', () {
        final logs = [
          {'timestamp': '2026-03-16T10:00:00', 'actualHydrationOz': 70.0, 'caffeineMg': 140.0},
        ];
        final stats = WeeklyStatsCalculator.compute(
          logs: logs, start: start, end: end, dailyGoalOz: 64.0,
        );
        expect(stats.avgHydrationOzPerDay, closeTo(70.0 / 7, 0.001));
        expect(stats.avgCaffeineMgPerDay, closeTo(140.0 / 7, 0.001));
      });
    });
  });
}
