import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/providers/hydration_provider.dart';

/// UserGoalsScreen - shows goals/badges based on today's real drink logs.

class UserGoalsScreen extends StatelessWidget {
  const UserGoalsScreen({super.key});

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

// 5) Consistency King – 3-day streak
_GoalCardData(
  title: 'Consistency King',
  statusLabel: provider.currentStreak >= 3 ? 'Earned' : 'In Progress',
  statusColor: provider.currentStreak >= 3 ? Colors.green : Colors.blue,
  description: 'Meet your daily goal 3 days in a row.',
  progressText: '${provider.currentStreak} / 3 day streak',
  progressValue: (provider.currentStreak / 3).clamp(0.0, 1.0),
  isLocked: provider.currentStreak < 3,
  icon: Icons.fire_hydrant
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

// 16) Hydration Habit – 14-day streak (bridges the gap between week and month)
_GoalCardData(
  title: 'Hydration Habit',
  statusLabel: provider.currentStreak >= 14 ? 'Earned' : 'In Progress',
  statusColor: provider.currentStreak >= 14 ? Colors.green : Colors.deepPurple,
  description: 'Build a 2-week hydration habit.',
  progressText: '${provider.currentStreak} / 14 day streak',
  progressValue: (provider.currentStreak / 14).clamp(0.0, 1.0),
  isLocked: provider.currentStreak < 14,
  icon: Icons.autorenew,
),

// 17) Marathon Month – 60-day streak
_GoalCardData(
  title: 'Marathon Month',
  statusLabel: provider.currentStreak >= 60 ? 'Earned' : 'Locked',
  statusColor: provider.currentStreak >= 60 ? Colors.green : Colors.grey,
  description: 'Maintain hydration for 60 days straight.',
  progressText: '${provider.currentStreak} / 60 days',
  progressValue: (provider.currentStreak / 60).clamp(0.0, 1.0),
  isLocked: provider.currentStreak < 60,
  icon: Icons.emoji_events,
),

// 18) Sunrise Sipper – log before 6 AM (harder than Early Bird)
_GoalCardData(
  title: 'Sunrise Sipper',
  statusLabel: provider.hasVeryEarlyLog ? 'Earned' : 'Locked',
  statusColor: provider.hasVeryEarlyLog ? Colors.green : Colors.grey,
  description: 'Log a drink before 6:00 AM.',
  progressText: provider.hasVeryEarlyLog ? 'Dawn hydration ✓' : 'Rise and hydrate!',
  progressValue: provider.hasVeryEarlyLog ? 1.0 : 0.0,
  isLocked: !provider.hasVeryEarlyLog,
  icon: Icons.wb_twilight,
),

// 19) Lunch Break – log between 11 AM and 1 PM
_GoalCardData(
  title: 'Lunch Break',
  statusLabel: provider.hasLunchLog ? 'Earned' : 'Locked',
  statusColor: provider.hasLunchLog ? Colors.green : Colors.grey,
  description: 'Stay hydrated during lunch (11 AM - 1 PM).',
  progressText: provider.hasLunchLog ? 'Midday hydration ✓' : 'Drink with lunch!',
  progressValue: provider.hasLunchLog ? 1.0 : 0.0,
  isLocked: !provider.hasLunchLog,
  icon: Icons.lunch_dining,
),

// 20) Afternoon Boost – log between 2 PM and 4 PM
_GoalCardData(
  title: 'Afternoon Boost',
  statusLabel: provider.hasAfternoonLog ? 'Earned' : 'Locked',
  statusColor: provider.hasAfternoonLog ? Colors.green : Colors.grey,
  description: 'Beat the afternoon slump (2 PM - 4 PM).',
  progressText: provider.hasAfternoonLog ? 'Afternoon boost ✓' : 'Power through!',
  progressValue: provider.hasAfternoonLog ? 1.0 : 0.0,
  isLocked: !provider.hasAfternoonLog,
  icon: Icons.coffee,
),

// 21) Weekend Warrior – meet goal on Saturday AND Sunday
_GoalCardData(
  title: 'Weekend Warrior',
  statusLabel: provider.weekendGoalsMet ? 'Earned' : 'In Progress',
  statusColor: provider.weekendGoalsMet ? Colors.green : Colors.orange,
  description: 'Hit your goal on both weekend days.',
  progressText: '${provider.weekendDaysCompleted} / 2 weekend days',
  progressValue: (provider.weekendDaysCompleted / 2).clamp(0.0, 1.0),
  isLocked: !provider.weekendGoalsMet,
  icon: Icons.weekend,
),

// 22) Water Purist – drink only water for a full day (meet goal with water only)
_GoalCardData(
  title: 'Water Purist',
  statusLabel: provider.isWaterOnlyDay && hydrationRatio >= 1.0 ? 'Earned' : 'In Progress',
  statusColor: provider.isWaterOnlyDay && hydrationRatio >= 1.0 ? Colors.green : Colors.cyan,
  description: 'Meet your goal drinking only water.',
  progressText: provider.isWaterOnlyDay ? 'Pure water day!' : 'Water only so far',
  progressValue: provider.isWaterOnlyDay && hydrationRatio >= 1.0 ? 1.0 : hydrationRatio * 0.5,
  isLocked: !(provider.isWaterOnlyDay && hydrationRatio >= 1.0),
  icon: Icons.opacity,
),

// 23) Beverage Connoisseur – log 5 different drink types in one day
_GoalCardData(
  title: 'Beverage Connoisseur',
  statusLabel: provider.uniqueDrinkTypesToday >= 5 ? 'Earned' : 'In Progress',
  statusColor: provider.uniqueDrinkTypesToday >= 5 ? Colors.green : Colors.deepOrange,
  description: 'Log 5 different drink types today.',
  progressText: '${provider.uniqueDrinkTypesToday} / 5 types',
  progressValue: (provider.uniqueDrinkTypesToday / 5).clamp(0.0, 1.0),
  isLocked: provider.uniqueDrinkTypesToday < 5,
  icon: Icons.wine_bar,
),

// 24) Double Down – hit your goal 2 days in a row
_GoalCardData(
  title: 'Double Down',
  statusLabel: provider.currentStreak >= 2 ? 'Earned' : 'In Progress',
  statusColor: provider.currentStreak >= 2 ? Colors.green : Colors.lightBlue,
  description: 'Meet your goal 2 days in a row.',
  progressText: '${provider.currentStreak} / 2 day streak',
  progressValue: (provider.currentStreak / 2).clamp(0.0, 1.0),
  isLocked: provider.currentStreak < 2,
  icon: Icons.looks_two,
),

// 25) Triple Threat – log 3 drinks within 1 hour
_GoalCardData(
  title: 'Triple Threat',
  statusLabel: provider.hasRapidLogs ? 'Earned' : 'Locked',
  statusColor: provider.hasRapidLogs ? Colors.green : Colors.grey,
  description: 'Log 3 drinks within a single hour.',
  progressText: provider.hasRapidLogs ? 'Speed hydration ✓' : 'Quick succession needed',
  progressValue: provider.hasRapidLogs ? 1.0 : 0.0,
  isLocked: !provider.hasRapidLogs,
  icon: Icons.bolt,
),

// 26) Steady Stream – log at least 1 drink every 2 hours (8 AM - 8 PM)
_GoalCardData(
  title: 'Steady Stream',
  statusLabel: provider.hasSteadyHydration ? 'Earned' : 'In Progress',
  statusColor: provider.hasSteadyHydration ? Colors.green : Colors.blueGrey,
  description: 'Log a drink every 2 hours throughout the day.',
  progressText: '${provider.hourlySlotsFilled} / 6 time slots',
  progressValue: (provider.hourlySlotsFilled / 6).clamp(0.0, 1.0),
  isLocked: !provider.hasSteadyHydration,
  icon: Icons.stream,
),

// 27) Mega Gulp – log a single drink of 32+ oz
_GoalCardData(
  title: 'Mega Gulp',
  statusLabel: provider.hasLargeDrink ? 'Earned' : 'Locked',
  statusColor: provider.hasLargeDrink ? Colors.green : Colors.grey,
  description: 'Log a single 32+ oz drink.',
  progressText: provider.hasLargeDrink ? 'Big gulp logged!' : 'Go big or go home',
  progressValue: provider.hasLargeDrink ? 1.0 : 0.0,
  isLocked: !provider.hasLargeDrink,
  icon: Icons.battery_charging_full,
),

// 28) Micro Sipper – log 10 small drinks (under 8 oz each) in one day
_GoalCardData(
  title: 'Micro Sipper',
  statusLabel: provider.smallDrinkCount >= 10 ? 'Earned' : 'In Progress',
  statusColor: provider.smallDrinkCount >= 10 ? Colors.green : Colors.lime,
  description: 'Log 10 small sips (under 8 oz each).',
  progressText: '${provider.smallDrinkCount} / 10 small drinks',
  progressValue: (provider.smallDrinkCount / 10).clamp(0.0, 1.0),
  isLocked: provider.smallDrinkCount < 10,
  icon: Icons.grain,
),

// 29) River Runner – 500 oz lifetime
_GoalCardData(
  title: 'River Runner',
  statusLabel: provider.lifetimeOunces >= 500 ? 'Earned' : 'In Progress',
  statusColor: provider.lifetimeOunces >= 500 ? Colors.green : Colors.lightBlue,
  description: 'Log 500 oz across your journey.',
  progressText: '${provider.lifetimeOunces.toStringAsFixed(0)} / 500 oz',
  progressValue: (provider.lifetimeOunces / 500).clamp(0.0, 1.0),
  isLocked: provider.lifetimeOunces < 500,
  icon: Icons.water,
),

// 30) Lake Legend – 5,000 oz lifetime
_GoalCardData(
  title: 'Lake Legend',
  statusLabel: provider.lifetimeOunces >= 5000 ? 'Earned' : 'Locked',
  statusColor: provider.lifetimeOunces >= 5000 ? Colors.green : Colors.grey,
  description: 'Reach 5,000 oz lifetime hydration.',
  progressText: '${provider.lifetimeOunces.toStringAsFixed(0)} / 5,000 oz',
  progressValue: (provider.lifetimeOunces / 5000).clamp(0.0, 1.0),
  isLocked: provider.lifetimeOunces < 5000,
  icon: Icons.pool,
),

// 31) Perfect Ten – log exactly 10 drinks in one day
_GoalCardData(
  title: 'Perfect Ten',
  statusLabel: logCount >= 10 ? 'Earned' : 'In Progress',
  statusColor: logCount >= 10 ? Colors.green : Colors.pink,
  description: 'Log 10 drinks in a single day.',
  progressText: '$logCount / 10 drinks',
  progressValue: (logCount / 10).clamp(0.0, 1.0),
  isLocked: logCount < 10,
  icon: Icons.forest
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

IconData _getGoalIcon(String title) {
  switch (title) {
    // Existing goals
    case 'First Sip':
      return Icons.water_drop_outlined;
    case 'Daily Drinker':
      return Icons.local_drink;
    case 'Frequent Sipper':
      return Icons.repeat;
    case 'Hydration Hero':
      return Icons.shield;
    case 'Consistency King':
      return Icons.fire_hydrant; // Note: Use emoji or custom if not available
    case 'Week Warrior':
      return Icons.calendar_view_week;
    case 'Monthly Master':
      return Icons.calendar_month;
    case 'Early Bird':
      return Icons.wb_sunny;
    case 'Night Owl':
      return Icons.nightlight_round;
    case 'Mixer':
      return Icons.blender;
    case 'Centurion':
      return Icons.military_tech;
    case 'Gallon Club':
      return Icons.workspace_premium;
    case 'Ocean Explorer':
      return Icons.sailing;
    case 'Overachiever':
      return Icons.trending_up;
    case 'Perfect Ten':
      return Icons.forest;
    
    // NEW GOALS
    case 'Splash Starter':
      return Icons.play_circle_outline;
    case 'Hydration Habit':
      return Icons.autorenew;
    case 'Marathon Month':
      return Icons.emoji_events;
    case 'Sunrise Sipper':
      return Icons.wb_twilight;
    case 'Lunch Break':
      return Icons.lunch_dining;
    case 'Afternoon Boost':
      return Icons.coffee;
    case 'Weekend Warrior':
      return Icons.weekend;
    case 'Water Purist':
      return Icons.opacity;
    case 'Beverage Connoisseur':
      return Icons.wine_bar;
    case 'Double Down':
      return Icons.looks_two;
    case 'Triple Threat':
      return Icons.looks_3;
    case 'Speed Demon':
      return Icons.bolt;
    case 'Steady Stream':
      return Icons.stream;
    case 'Mega Gulp':
      return Icons.battery_charging_full;
    case 'Micro Sipper':
      return Icons.grain;
    case 'Comeback Kid':
      return Icons.refresh;
    case 'River Runner':
      return Icons.water;
    case 'Lake Legend':
      return Icons.pool;
    case 'Hydration Station':
      return Icons.ev_station;
    
    default:
      return Icons.water_drop;
  }
}

class _GoalCardData {
  final String title;
  final String statusLabel;
  final Color statusColor;
  final String description;
  final String? progressText;
  final double? progressValue; // 0.0–1.0
  final bool isLocked;
  final IconData icon;

  _GoalCardData({
    required this.title,
    required this.statusLabel,
    required this.statusColor,
    required this.description,
    this.progressText,
    this.progressValue,
    this.isLocked = false,
    this.icon = Icons.water_drop,
  });
}

class _GoalCard extends StatelessWidget {
  final _GoalCardData goal;

  const _GoalCard({super.key, required this.goal});

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
                  goal.isLocked ? Icons.lock : goal.icon,
                  color: goal.isLocked ? Colors.grey : goal.statusColor,
                  size: 24,
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
