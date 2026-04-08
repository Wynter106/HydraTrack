import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/providers/hydration_provider.dart';
import '../../business/calculators/monthly_stats_calculator.dart';
import '../widgets/app_card.dart';

class MonthlyStatsScreen extends StatelessWidget {
  const MonthlyStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HydrationProvider>(context);

    final (start, end) = MonthlyStatsCalculator.currentMonthRange(DateTime.now());
    final logs = provider.getLogsBetween(start, end);

    final stats = MonthlyStatsCalculator.compute(
      logs: logs,
      start: start,
      end: end,
      dailyGoalOz: provider.hydrationGoal,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Stats')),
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
                const Text('Summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
                const Text('Goal Achievement',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
                  'Monthly Calendar View',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _buildMonthlyCalendar(context, stats.daily, provider.hydrationGoal),
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

Widget _buildMonthlyCalendar(
  BuildContext context,
  List<DayStats> daily,
  double goalOz,
) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final cells = _buildMonthlyGridData(daily);

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
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cells.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 0.6,
        ),
        itemBuilder: (context, index) {
          final d = cells[index];
          if (d == null) return const SizedBox.shrink();
          return _buildMonthCell(context, d, goalOz);
        },
      ),
    ],
  );
}

List<DayStats?> _buildMonthlyGridData(List<DayStats> daily) {
  if (daily.isEmpty) return [];

  final firstDay = daily.first.day;
  final weekdayOffset = firstDay.weekday - 1; // Monday=1 -> 0 offset

  final result = <DayStats?>[];
  for (int i = 0; i < weekdayOffset; i++) {
    result.add(null);
  }
  result.addAll(daily);
  return result;
}

Widget _buildMonthCell(BuildContext context, DayStats d, double goalOz) {
  final metGoal = d.hydrationOz >= goalOz;
  final isToday = _dayOnly(d.day) == _dayOnly(DateTime.now());

  final bgColor = metGoal
      ? Colors.blue.withValues(alpha: 0.12)
      : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);

  final borderColor = isToday
      ? Theme.of(context).colorScheme.primary
      : Colors.transparent;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: borderColor, width: isToday ? 1.5 : 0),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${d.day.day}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${d.hydrationOz.toStringAsFixed(0)} oz',
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
