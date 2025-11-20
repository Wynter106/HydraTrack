import 'package:flutter/material.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';

class DrinkLibraryScreen extends StatelessWidget {
  const DrinkLibraryScreen({super.key});

  // Hardcoded mock drinks for now (will be replaced by DB later)
  static const List<Map<String, dynamic>> _mockDrinks = [
    {
      'name': 'Water',
      'volumeOz': 8,
      'caffeineMg': 0,
      'hydrationFactor': 1.0,
    },
    {
      'name': 'Black Coffee',
      'volumeOz': 8,
      'caffeineMg': 95,
      'hydrationFactor': 0.7,
    },
    {
      'name': 'Latte',
      'volumeOz': 12,
      'caffeineMg': 80,
      'hydrationFactor': 0.8,
    },
    {
      'name': 'Green Tea',
      'volumeOz': 8,
      'caffeineMg': 35,
      'hydrationFactor': 0.9,
    },
    {
      'name': 'Energy Drink',
      'volumeOz': 16,
      'caffeineMg': 160,
      'hydrationFactor': 0.6,
    },
    {
      'name': 'Soda',
      'volumeOz': 12,
      'caffeineMg': 40,
      'hydrationFactor': 0.8,
    },
    {
      'name': 'Sports Drink',
      'volumeOz': 16,
      'caffeineMg': 0,
      'hydrationFactor': 1.1,
    },
    {
      'name': 'Milk',
      'volumeOz': 8,
      'caffeineMg': 0,
      'hydrationFactor': 1.0,
    },
    {
      'name': 'Decaf Coffee',
      'volumeOz': 8,
      'caffeineMg': 5,
      'hydrationFactor': 0.9,
    },
    {
      'name': 'Iced Tea',
      'volumeOz': 12,
      'caffeineMg': 60,
      'hydrationFactor': 0.8,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drink Library'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top info / future filters
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Browse available drinks',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.separated(
                itemCount: _mockDrinks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final drink = _mockDrinks[index];

                  return AppCard(
                    child: ListTile(
                      title: Text(drink['name'] as String),
                      subtitle: Text(
                        'Volume: ${drink['volumeOz']} oz\n'
                        'Caffeine: ${drink['caffeineMg']} mg  |  '
                        'Hydration: ${drink['hydrationFactor']}x',
                      ),
                      isThreeLine: true,
                      onTap: () {
                        debugPrint('Selected ${drink['name']}');
                        // Later: open drink details / add to log
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Temporary back button (can also use system back)
            AppButton(
              label: 'Back to Home',
              filled: false,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
