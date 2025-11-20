import 'package:flutter/material.dart';

class UserGoalsScreen extends StatelessWidget {
  const UserGoalsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Simple dummy data goals.
    final goals = <_GoalCardData>[
      _GoalCardData(
        title: 'First Sip',
        statusLabel: 'Earned',
        statusColor: Colors.green,
        description: 'Earned on Jan 5, 2023',
        progressText: null,
        isLocked: false,
      ),
      _GoalCardData(
        title: 'Daily Drinker',
        statusLabel: 'In Progress',
        statusColor: Colors.blue,
        description: '7 / 10 Days',
        progressText: '7/10 Days',
        progressValue: 0.7,
        isLocked: false,
      ),
      _GoalCardData(
        title: 'Hydration Hero',
        statusLabel: 'Earned',
        statusColor: Colors.green,
        description: 'Earned on Mar 12, 2023',
        progressText: null,
        isLocked: false,
      ),
      _GoalCardData(
        title: 'Streak Master',
        statusLabel: 'Locked',
        statusColor: Colors.grey,
        description: 'Stay hydrated 30 days in a row',
        progressText: '25/50 Days',
        progressValue: 0.5,
        isLocked: true,
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

// ----- Helper classes/widgets just for this screen

class _GoalCardData {
  final String title;
  final String statusLabel;
  final Color statusColor;
  final String description;
  final String? progressText;
  final double? progressValue;
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
                backgroundColor:
                    goal.isLocked ? Colors.grey.shade300 : Colors.blue.shade100,
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
                value: goal.progressValue,
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