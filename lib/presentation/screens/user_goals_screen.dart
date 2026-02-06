import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/providers/hydration_provider.dart';

/// UserGoalsScreen - shows goals/badges based on today's real drink logs.

class UserGoalsScreen extends StatelessWidget {
  const UserGoalsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Watch provider for changes
    final provider = Provider.of<HydrationProvider>(context);

    final double hydrationCurrent = provider.hydrationCurrent;
    final double hydrationGoal = provider.hydrationGoal;
    final double hydrationRatio =
        provider.hydrationProgress.clamp(0.0, 1.0);

    final int logCount = provider.todayLogs.length;
    final double overachieverTarget = hydrationGoal * 1.5;

    // Avoid divide by zero
    final double heroTarget = (hydrationGoal * 2).clamp(1.0, double.infinity);

    final goals = <_GoalCardData>[
      // 1) First Sip
      _GoalCardData(
        title: 'First Sip',
        statusLabel: hydrationCurrent > 0 ? 'Earned' : 'Locked',
        statusColor: hydrationCurrent > 0 ? Colors.green : Colors.grey,
        description: 'Log at least one drink today.',
        progressText: hydrationCurrent > 0
            ? '${hydrationCurrent.toStringAsFixed(1)} oz logged'
            : 'No drinks yet',
        progressValue: hydrationCurrent > 0 ? 1.0 : 0.0,
        isLocked: hydrationCurrent == 0,
      ),

      // 2) Daily Drinker – hit your daily goal
      _GoalCardData(
        title: 'Daily Drinker',
        statusLabel:
            hydrationRatio >= 1.0 ? 'Earned' : 'In Progress',
        statusColor:
            hydrationRatio >= 1.0 ? Colors.green : Colors.blue,
        description: 'Reach your daily hydration goal.',
        progressText:
            '${hydrationCurrent.toStringAsFixed(1)} / ${hydrationGoal.toStringAsFixed(0)} oz',
        progressValue: hydrationRatio,
        isLocked: false,
      ),

      // 3) Frequent Sipper – log 3 drinks in one day
      _GoalCardData(
        title: 'Frequent Sipper',
        statusLabel: logCount >= 3 ? 'Earned' : 'In Progress',
        statusColor: logCount >= 3 ? Colors.green : Colors.blue,
        description: 'Log drinks 3 times in a single day.',
        progressText: '$logCount / 3 drinks',
        progressValue: (logCount / 3).clamp(0.0, 1.0),
        isLocked: logCount < 3,
      ),

      // 4) Hydration Hero – 2× daily goal
      _GoalCardData(
        title: 'Hydration Hero',
        statusLabel: hydrationCurrent >= heroTarget
            ? 'Earned'
            : 'In Progress',
        statusColor: hydrationCurrent >= heroTarget
            ? Colors.green
            : Colors.orange,
        description: 'Drink 2× your daily goal in one day.',
        progressText:
            '${hydrationCurrent.toStringAsFixed(1)} / ${heroTarget.toStringAsFixed(0)} oz',
        progressValue:
            (hydrationCurrent / heroTarget).clamp(0.0, 1.0),
        isLocked: hydrationCurrent < heroTarget,
      ),
      // ===== STREAK GOALS =====

// 5) Consistency King – 3-day streak
_GoalCardData(
  title: 'Consistency King',
  statusLabel: provider.currentStreak >= 3 ? 'Earned' : 'In Progress',
  statusColor: provider.currentStreak >= 3 ? Colors.green : Colors.blue,
  description: 'Meet your daily goal 3 days in a row.',
  progressText: '${provider.currentStreak} / 3 day streak',
  progressValue: (provider.currentStreak / 3).clamp(0.0, 1.0),
  isLocked: provider.currentStreak < 3,
),

// 6) Week Warrior – 7-day streak
_GoalCardData(
  title: 'Week Warrior',
  statusLabel: provider.currentStreak >= 7 ? 'Earned' : 'In Progress',
  statusColor: provider.currentStreak >= 7 ? Colors.green : Colors.purple,
  description: 'Hit your goal every day for a full week.',
  progressText: '${provider.currentStreak} / 7 day streak',
  progressValue: (provider.currentStreak / 7).clamp(0.0, 1.0),
  isLocked: provider.currentStreak < 7,
),

// 7) Monthly Master – 30-day streak
_GoalCardData(
  title: 'Monthly Master',
  statusLabel: provider.currentStreak >= 30 ? 'Earned' : 'Locked',
  statusColor: provider.currentStreak >= 30 ? Colors.green : Colors.grey,
  description: 'Maintain a 30-day hydration streak.',
  progressText: '${provider.currentStreak} / 30 days',
  progressValue: (provider.currentStreak / 30).clamp(0.0, 1.0),
  isLocked: provider.currentStreak < 30,
),


// ===== TIME-BASED GOALS =====

// 8) Early Bird – log before 8 AM
_GoalCardData(
  title: 'Early Bird',
  statusLabel: provider.hasEarlyLog ? 'Earned' : 'Locked',
  statusColor: provider.hasEarlyLog ? Colors.green : Colors.grey,
  description: 'Log a drink before 8:00 AM.',
  progressText: provider.hasEarlyLog ? 'Morning hydration ✓' : 'Wake up and hydrate!',
  progressValue: provider.hasEarlyLog ? 1.0 : 0.0,
  isLocked: !provider.hasEarlyLog,
),

// 9) Night Owl – log after 9 PM
_GoalCardData(
  title: 'Night Owl',
  statusLabel: provider.hasLateLog ? 'Earned' : 'Locked',
  statusColor: provider.hasLateLog ? Colors.green : Colors.grey,
  description: 'Log a drink after 9:00 PM.',
  progressText: provider.hasLateLog ? 'Evening hydration ✓' : 'Stay hydrated tonight',
  progressValue: provider.hasLateLog ? 1.0 : 0.0,
  isLocked: !provider.hasLateLog,
),


// ===== VARIETY GOALS =====

// 10) Mixer – log 3 different drink types in one day
_GoalCardData(
  title: 'Mixer',
  statusLabel: provider.uniqueDrinkTypesToday >= 3 ? 'Earned' : 'In Progress',
  statusColor: provider.uniqueDrinkTypesToday >= 3 ? Colors.green : Colors.teal,
  description: 'Log 3 different drink types today.',
  progressText: '${provider.uniqueDrinkTypesToday} / 3 types',
  progressValue: (provider.uniqueDrinkTypesToday / 3).clamp(0.0, 1.0),
  isLocked: provider.uniqueDrinkTypesToday < 3,
),


// ===== CUMULATIVE / LIFETIME GOALS =====

// 11) Centurion – 100 oz lifetime
_GoalCardData(
  title: 'Centurion',
  statusLabel: provider.lifetimeOunces >= 100 ? 'Earned' : 'In Progress',
  statusColor: provider.lifetimeOunces >= 100 ? Colors.green : Colors.blue,
  description: 'Log 100 oz total across all time.',
  progressText: '${provider.lifetimeOunces.toStringAsFixed(0)} / 100 oz',
  progressValue: (provider.lifetimeOunces / 100).clamp(0.0, 1.0),
  isLocked: provider.lifetimeOunces < 100,
),

// 12) Gallon Club – 128 oz (1 gallon) lifetime
_GoalCardData(
  title: 'Gallon Club',
  statusLabel: provider.lifetimeOunces >= 128 ? 'Earned' : 'In Progress',
  statusColor: provider.lifetimeOunces >= 128 ? Colors.green : Colors.indigo,
  description: 'Drink a total of 1 gallon lifetime.',
  progressText: '${provider.lifetimeOunces.toStringAsFixed(0)} / 128 oz',
  progressValue: (provider.lifetimeOunces / 128).clamp(0.0, 1.0),
  isLocked: provider.lifetimeOunces < 128,
),

// 13) Ocean Explorer – 1,000 oz lifetime
_GoalCardData(
  title: 'Ocean Explorer',
  statusLabel: provider.lifetimeOunces >= 1000 ? 'Earned' : 'Locked',
  statusColor: provider.lifetimeOunces >= 1000 ? Colors.green : Colors.grey,
  description: 'Log 1,000 oz across your journey.',
  progressText: '${provider.lifetimeOunces.toStringAsFixed(0)} / 1,000 oz',
  progressValue: (provider.lifetimeOunces / 1000).clamp(0.0, 1.0),
  isLocked: provider.lifetimeOunces < 1000,
),


// ===== CHALLENGE GOALS =====

// 14) Overachiever – exceed goal by 50%
_GoalCardData(
  title: 'Overachiever',
  statusLabel: hydrationCurrent >= overachieverTarget ? 'Earned' : 'In Progress',
  statusColor: hydrationCurrent >= overachieverTarget ? Colors.green : Colors.amber,
  description: 'Exceed your daily goal by 50%.',
  progressText: '${hydrationCurrent.toStringAsFixed(1)} / ${overachieverTarget.toStringAsFixed(0)} oz',
  progressValue: (hydrationCurrent / overachieverTarget).clamp(0.0, 1.0),
  isLocked: hydrationCurrent < overachieverTarget,
),

// 15) Perfect Ten – log exactly 10 drinks in one day
_GoalCardData(
  title: 'Perfect Ten',
  statusLabel: logCount >= 10 ? 'Earned' : 'In Progress',
  statusColor: logCount >= 10 ? Colors.green : Colors.pink,
  description: 'Log 10 drinks in a single day.',
  progressText: '$logCount / 10 drinks',
  progressValue: (logCount / 10).clamp(0.0, 1.0),
  isLocked: logCount < 10,
),
    ];
    

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals & Badges'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: GridView.builder(
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
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
        ),
      ),
    );
  }
}

// ===== Helper classes/data for this screen only =====

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
