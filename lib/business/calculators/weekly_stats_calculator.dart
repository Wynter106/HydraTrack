DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

class DayStats {
  final DateTime day;
  final double hydrationOz;
  final double caffeineMg;

  const DayStats({
    required this.day,
    required this.hydrationOz,
    required this.caffeineMg,
  });
}

class WeeklyStats {
  final DateTime start; // Monday
  final DateTime end;   // Sunday

  final double totalHydrationOz;
  final double avgHydrationOzPerDay;

  final double totalCaffeineMg;
  final double avgCaffeineMgPerDay;

  final int totalDays;
  final int goalMetDays;
  final double goalMetRate; // 0~1

  final List<DayStats> daily;

  const WeeklyStats({
    required this.start,
    required this.end,
    required this.totalHydrationOz,
    required this.avgHydrationOzPerDay,
    required this.totalCaffeineMg,
    required this.avgCaffeineMgPerDay,
    required this.totalDays,
    required this.goalMetDays,
    required this.goalMetRate,
    required this.daily,
  });
}

class WeeklyStatsCalculator {
  static (DateTime start, DateTime end) currentWeekRange(DateTime now) {
    final today = _day(now);
    final start = today.subtract(Duration(days: today.weekday - 1)); // Mon
    final end = start.add(const Duration(days: 6)); // Sun
    return (start, end);
  }

  static WeeklyStats compute({
    required List<Map<String, dynamic>> logs,
    required DateTime start,
    required DateTime end,
    required double dailyGoalOz,
  }) {
    final s = _day(start);
    final e = _day(end);

    // day -> (hydration, caffeine)
    final Map<DateTime, (double hyd, double caf)> sums = {};

    for (final log in logs) {
      final ts = log['timestamp'] as String?;
      final dt = ts == null ? null : DateTime.tryParse(ts);
      if (dt == null) continue;

      final d = _day(dt);
      if (d.isBefore(s) || d.isAfter(e)) continue;

      final hyd = (log['actualHydrationOz'] as num?)?.toDouble() ?? 0.0;
      final caf = (log['caffeineMg'] as num?)?.toDouble() ?? 0.0;

      final prev = sums[d] ?? (0.0, 0.0);
      sums[d] = (prev.$1 + hyd, prev.$2 + caf);
    }

    final List<DayStats> daily = [];
    int goalMetDays = 0;

    for (DateTime d = s; !d.isAfter(e); d = d.add(const Duration(days: 1))) {
      final v = sums[d];
      final hyd = v?.$1 ?? 0.0;
      final caf = v?.$2 ?? 0.0;
      if (hyd >= dailyGoalOz) goalMetDays++;
      daily.add(DayStats(day: d, hydrationOz: hyd, caffeineMg: caf));
    }

    final totalHyd = daily.fold(0.0, (a, x) => a + x.hydrationOz);
    final totalCaf = daily.fold(0.0, (a, x) => a + x.caffeineMg);

    final totalDays = daily.length;
    final avgHyd = totalDays == 0 ? 0.0 : totalHyd / totalDays;
    final avgCaf = totalDays == 0 ? 0.0 : totalCaf / totalDays;

    final rate = totalDays == 0 ? 0.0 : goalMetDays / totalDays;

    return WeeklyStats(
      start: s,
      end: e,
      totalHydrationOz: totalHyd,
      avgHydrationOzPerDay: avgHyd,
      totalCaffeineMg: totalCaf,
      avgCaffeineMgPerDay: avgCaf,
      totalDays: totalDays,
      goalMetDays: goalMetDays,
      goalMetRate: rate,
      daily: daily,
    );
  }
}
