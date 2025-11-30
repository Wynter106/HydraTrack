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
