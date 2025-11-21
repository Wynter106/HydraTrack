import 'package:flutter/material.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import 'drink_library_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Temporary placeholder data
    const int hydrationCurrent = 1200;
    const int hydrationGoal = 2000;
    const int caffeineCurrent = 150;
    const int caffeineLimit = 400;

    final hydrationRatio = hydrationCurrent / hydrationGoal;
    final caffeineRatio = caffeineCurrent / caffeineLimit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HydraTrack'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Today overview',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            // Summary card for today's status
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hydration',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: hydrationRatio),
                  const SizedBox(height: 4),
                  Text('$hydrationCurrent / $hydrationGoal ml'),

                  const SizedBox(height: 16),

                  const Text(
                    'Caffeine',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: caffeineRatio),
                  const SizedBox(height: 4),
                  Text('$caffeineCurrent / $caffeineLimit mg'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            AppButton(
             label: 'Open Drink Library',
              filled: false,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DrinkLibraryScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            AppButton(
              label: 'Open Log Screen  (TODO)',
              filled: false,
              onPressed: () {
                debugPrint('TODO: navigate to log screen');
              },
            ),
          ],
        ),
      ),
    );
  }
}
