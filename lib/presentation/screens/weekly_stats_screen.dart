import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/providers/hydration_provider.dart';
import '../../business/calculators/weekly_stats_calculator.dart';
import '../widgets/app_card.dart';

class WeeklyStatsScreen extends StatelessWidget {
  const WeeklyStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HydrationProvider>(context);

    final (start, end) = WeeklyStatsCalculator.currentWeekRange(DateTime.now());
    final logs = provider.getLogsBetween(start, end);

    final stats = WeeklyStatsCalculator.compute(
      logs: logs,
      start: start,
      end: end,
      dailyGoalOz: provider.hydrationGoal,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Stats')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_fmt(stats.start)} ~ ${_fmt(stats.end)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                const Text(
                  'Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text('Total Hydration: ${stats.totalHydrationOz.toStringAsFixed(1)} oz'),
                Text('Avg Hydration/Day: ${stats.avgHydrationOzPerDay.toStringAsFixed(1)} oz'),
                const SizedBox(height: 8),
                Text('Total Caffeine: ${stats.totalCaffeineMg.toStringAsFixed(0)} mg'),
                Text('Avg Caffeine/Day: ${stats.avgCaffeineMgPerDay.toStringAsFixed(0)} mg'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Goal Achievement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text('${stats.goalMetDays} / ${stats.totalDays} days met'),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: stats.goalMetRate.clamp(0.0, 1.0)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...stats.daily.map((d) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(d.day)),
                          Text('${d.hydrationOz.toStringAsFixed(1)} oz'),
                          Text('${d.caffeineMg.toStringAsFixed(0)} mg'),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
