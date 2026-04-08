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
                  'Weekly Calendar View',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _buildWeeklyCalendar(context, stats.daily, provider.hydrationGoal),
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

Widget _buildWeeklyCalendar(
  BuildContext context,
  List<DayStats> daily,
  double goalOz,
) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  return Column(
    children: [
      Row(
        children: labels
            .map(
              (label) => Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: daily
            .map(
              (d) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _buildDayCell(context, d, goalOz),
                ),
              ),
            )
            .toList(),
      ),
    ],
  );
}

Widget _buildDayCell(BuildContext context, DayStats d, double goalOz) {
  final metGoal = d.hydrationOz >= goalOz;
  final isToday = _dayOnly(d.day) == _dayOnly(DateTime.now());

  final bgColor = metGoal
      ? Colors.blue.withValues(alpha: 0.12)
      : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);

  final borderColor = isToday
      ? Theme.of(context).colorScheme.primary
      : Colors.transparent;

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor, width: isToday ? 1.5 : 0),
    ),
    child: Column(
      children: [
        Text(
          '${d.day.day}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          '${d.hydrationOz.toStringAsFixed(0)} oz',
          style: const TextStyle(fontSize: 11),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          '${d.caffeineMg.toStringAsFixed(0)} mg',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Icon(
          metGoal ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: metGoal ? Colors.blue : Colors.grey,
        ),
      ],
    ),
  );
}

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
