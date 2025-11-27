import 'package:flutter/material.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../../data/dao/beverages_dao.dart';
import '../../data/models/beverage.dart'; 

class DrinkLibraryScreen extends StatefulWidget {
  const DrinkLibraryScreen({super.key});

  @override
  State<DrinkLibraryScreen> createState() => _DrinkLibraryScreenState();
}

class _DrinkLibraryScreenState extends State<DrinkLibraryScreen> {

  final BeverageDao dao = BeverageDao();
  List<Beverage> beverages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBeverages();
  }

  Future<void> _loadBeverages() async {
    try {
      final result = await dao.getAllBeverages();
      setState(() {
        beverages = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error loading beverages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load drinks: $e')),
        );
      }
    }
  }

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

            if (isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )

            else if (beverages.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No drinks found in database'),
                ),
              )

            else
              Expanded(
                child: ListView.separated(
                  itemCount: beverages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final beverage = beverages[index];
                    final totalCaffeine = beverage.caffeinePerOz * beverage.defaultVolumeOz;

                    return AppCard(
                      child: ListTile(
                        title: Text(beverage.name),
                        subtitle: Text(
                          'Volume: ${beverage.defaultVolumeOz.toStringAsFixed(1)} oz\n'
                          'Caffeine: ${totalCaffeine.toStringAsFixed(0)} mg  |  '
                          'Hydration: ${beverage.hydrationFactor.toStringAsFixed(2)}x',
                        ),
                        isThreeLine: true,
                        onTap: () {
                          // Delete this comment later
                          // debugPrint('Selected ${beverage.name}');
                          Navigator.pop(context, beverage);
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
