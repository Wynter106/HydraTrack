import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_card.dart';
import '../../data/dao/beverages_dao.dart';
import '../../data/models/beverage.dart';
import '../../application/providers/hydration_provider.dart';
import '../../application/providers/profile_provider.dart';

/// AlcoholHomeScreen - Main screen for alcohol tracking
class AlcoholHomeScreen extends StatefulWidget {
  const AlcoholHomeScreen({super.key});

  @override
  State<AlcoholHomeScreen> createState() => _AlcoholHomeScreenState();
}

class _AlcoholHomeScreenState extends State<AlcoholHomeScreen> {
  final BeverageDao dao = BeverageDao();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileProvider = context.read<ProfileProvider>();
      final hydrationProvider = context.read<HydrationProvider>();

      await profileProvider.loadProfile();
      hydrationProvider.setAlcoholLimit(profileProvider.dailyAlcoholLimit);
    });
  }

  /// Opens Alcohol DrinkLibrary and handles selected beverage
  Future<void> _openAlcoholDrinkLibrary() async {
    final selectedBeverage = await Navigator.pushNamed(context, '/alclib');

    if (selectedBeverage != null && selectedBeverage is Beverage) {
      if (!mounted) return;
      final provider = context.read<HydrationProvider>();
      await provider.addDrink(selectedBeverage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HydrationProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    final alcoholLimit = profileProvider.dailyAlcoholLimit;

    final alcoholRatio = alcoholLimit > 0
        ? (provider.alcoholCurrent / alcoholLimit).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HydraTrack'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==================== TODAY'S PROGRESS ====================
            Text(
              'Today overview',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alcohol',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: alcoholRatio,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      (provider.alcoholCurrent / alcoholLimit >= 0.8)
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${provider.alcoholCurrent.toStringAsFixed(1)} / '
                    '$alcoholLimit standard drinks',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==================== ADD DRINK BUTTON ====================
            ElevatedButton.icon(
              onPressed: _openAlcoholDrinkLibrary,
              icon: const Icon(Icons.add),
              label: const Text('Add Alcohol Drink'),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),

      // ==================== BOTTOM NAVIGATION ====================
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/home');
              break;
            case 1:
              Navigator.pushNamed(context, '/log');
              break;
            case 2:
              Navigator.pushNamed(context, '/goals');
              break;
            case 3:
              break; // already here
            case 4:
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Goals'),
          BottomNavigationBarItem(icon: Icon(Icons.local_bar), label: 'Alcohol'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
