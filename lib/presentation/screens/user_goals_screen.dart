import 'package:flutter/material.dart';
import '../../data/dao/drink_logs_dao.dart';

/// Screen that shows user goals / badges based on real drink logs.
class UserGoalsScreen extends StatefulWidget {
  const UserGoalsScreen({Key? key}) : super(key: key);

  @override
  State<UserGoalsScreen> createState() => _UserGoalsScreenState();
}

class _UserGoalsScreenState extends State<UserGoalsScreen> {
  // Data access object for drink logs
  final DrinkLogDao _drinkLogDao = DrinkLogDao();

  late Future<_GoalsData> _goalsFuture;

  // For now, fixed daily goal. Later you can load this from UserSettings.
  static const double _dailyGoalOz = 64.0;

  @override
  void initState() {
    super.initState();
    _goalsFuture = _loadGoals();
  }

  Future<_GoalsData> _loadGoals() async {
    final today = DateTime.now();

    final totalToday = await _drinkLogDao.getTotalHydrationOzForDay(today);
    final streak = await _drinkLogDao.getStreakCount(_dailyGoalOz);

    final percentToday =
        (totalToday / _dailyGoalOz).clamp(0.0, 1.0) as double;

    return _GoalsData(
      totalTodayOz: totalToday,
      goalOz: _dailyGoalOz,
      todayPercent: percentToday,
      streakDays: streak,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals & Badges'),
      ),
      body: SafeArea(
        child: FutureBuilder<_GoalsData>(
          future: _goalsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading goals: ${snapshot.error}'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('No goal data yet.'));
            }

            final data = snapshot.data!;

            // Build cards using REAL progress now
            final goals = <_GoalCardData>[
              _GoalCardData(
                title: 'First Sip',
                statusLabel:
                    data.totalTodayOz > 0 ? 'Earned' : 'Locked',
                statusColor:
                    data.totalTodayOz > 0 ? Colors.green : Colors.grey,
                description: 'Log at least one drink.',
                progressText: null,
                progressValue: null,
                isLocked: data.totalTodayOz == 0,
              ),
              _GoalCardData(
                title: 'Daily Drinker',
                statusLabel:
                    data.todayPercent >= 1.0 ? 'Earned' : 'In Progress',
                statusColor:
                    data.todayPercent >= 1.0 ? Colors.green : Colors.blue,
                description: 'Hit your daily hydration goal.',
                progressText:
                    '${data.totalTodayOz.toStringAsFixed(0)}/${data.goalOz.toStringAsFixed(0)} oz',
                progressValue: data.todayPercent,
                isLocked: false,
              ),
              _GoalCardData(
                title: 'Streak Master',
                statusLabel: data.streakDays >= 7 ? 'Earned' : 'In Progress',
                statusColor:
                    data.streakDays >= 7 ? Colors.green : Colors.blue,
                description: 'Stay hydrated for 7 days in a row.',
                progressText: '${data.streakDays}/7 Days',
                progressValue:
                    (data.streakDays / 7).clamp(0.0, 1.0) as double,
                isLocked: data.streakDays < 7,
              ),
              _GoalCardData(
                title: 'Hydration Hero',
                statusLabel: data.streakDays >= 30 ? 'Earned' : 'Locked',
                statusColor:
                    data.streakDays >= 30 ? Colors.green : Colors.grey,
                description: 'Stay hydrated for 30 days in a row.',
                progressText: '${data.streakDays}/30 Days',
                progressValue:
                    (data.streakDays / 30).clamp(0.0, 1.0) as double,
                isLocked: data.streakDays < 30,
              ),
            ];

            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // two cards per row
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  return _GoalCard(goal: goal);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// ===== Helper classes/data for this screen only =====

class _GoalsData {
  final double totalTodayOz;
  final double goalOz;
  final double todayPercent; // 0–1
  final int streakDays;

  _GoalsData({
    required this.totalTodayOz,
    required this.goalOz,
    required this.todayPercent,
    required this.streakDays,
  });
}

class _GoalCardData {
  final String title;
  final String statusLabel;
  final Color statusColor;
  final String description;
  final String? progressText;
  final double? progressValue; // 0.0–1.0
  final bool isLocked;

  _GoalCardData({
    required this.title,
    required this.statusLabel,
    required this.statusColor,
    required this.description,
    this.progressText,
    this.progressValue,
    this.isLocked = false,
  });
}

class _GoalCard extends StatelessWidget {
  final _GoalCardData goal;

  const _GoalCard({Key? key, required this.goal}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top icon / avatar placeholder
            Center(
              child: CircleAvatar(
                radius: 22,
                backgroundColor: goal.isLocked
                    ? Colors.grey.shade300
                    : Colors.blue.shade100,
                child: Icon(
                  goal.isLocked ? Icons.lock : Icons.water_drop,
                  color: goal.isLocked ? Colors.grey : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              goal.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Status pill
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: goal.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                goal.statusLabel,
                style: TextStyle(
                  color: goal.statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              goal.description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // Optional progress bar
            if (goal.progressValue != null) ...[
              LinearProgressIndicator(
                value: goal.progressValue!.clamp(0.0, 1.0),
                minHeight: 4,
              ),
              const SizedBox(height: 4),
              Text(
                goal.progressText ?? '',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
