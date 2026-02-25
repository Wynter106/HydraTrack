import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_card.dart';
import '../../data/dao/beverages_dao.dart';
import '../../data/models/beverage.dart';
import '../../application/providers/hydration_provider.dart';
import '../../application/providers/profile_provider.dart';
import '../../application/providers/favorite_drinks_provider.dart'; // Added!
import '../../data/models/favorite_drink.dart'; // Added!

/// HomeScreen - Main screen showing hydration progress and quick add buttons
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BeverageDao dao = BeverageDao();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileProvider = context.read<ProfileProvider>();
      final hydrationProvider = context.read<HydrationProvider>();
      final favProvider = context.read<FavoriteDrinksProvider>(); // Added!

      // Load profile
      await profileProvider.loadProfile();

      // Set goals
      hydrationProvider.setHydrationGoal(profileProvider.dailyHydrationGoalOz.toDouble());
      hydrationProvider.setCaffeineLimit(profileProvider.dailyCaffeineLimitMg.toDouble());

      // Load today's logs
      await hydrationProvider.loadTodayLogs();

      // Load favorites first
      await favProvider.loadFavorites();

      // Initialize defaults ONLY if empty
      if (favProvider.favorites.isEmpty) {
        debugPrint('🔵 No favorites found, initializing defaults...');
        await favProvider.initializeDefaults();
      }

      debugPrint('✅ Loaded ${favProvider.favorites.length} favorites');
      debugPrint('✅ Quick Add count: ${favProvider.quickAddFavorites.length}');

      debugPrint('✅ Loaded ${favProvider.favorites.length} favorites');
      debugPrint('✅ Quick Add count: ${favProvider.quickAddFavorites.length}');
    });
  }

  /// Quick add drink from favorites
  Future<void> _quickAddDrink(FavoriteDrink favorite) async {
    try {
      // Get beverage from database
      final beverage = await dao.getBeverageByExactName(favorite.beverageName);

      if (beverage == null) {
        debugPrint('Error: Beverage not found: ${favorite.beverageName}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Drink not found: ${favorite.beverageName}')),
          );
        }
        return;
      }

      // Use custom volume or default
      final volumeOz = (favorite.customVolumeOz ?? beverage.defaultVolumeOz).toDouble();

      // Add to hydration provider
      final provider = context.read<HydrationProvider>();
      await provider.addDrink(beverage, volumeOz: volumeOz);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${volumeOz.toStringAsFixed(1)} oz of ${favorite.beverageName}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding drink: $e');
    }
  }

  /// Opens DrinkLibrary and handles selected beverage
  Future<void> _openDrinkLibrary() async {
    final selectedBeverage = await Navigator.pushNamed(context, '/library');

    if (selectedBeverage != null && selectedBeverage is Beverage) {
      final provider = context.read<HydrationProvider>();
      await provider.addDrink(selectedBeverage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HydrationProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final favProvider = context.watch<FavoriteDrinksProvider>(); // Added!

    final hydrationGoal = profileProvider.dailyHydrationGoalOz;
    final caffeineLimit = profileProvider.dailyCaffeineLimitMg;
    final volumeUnit = profileProvider.preferredVolumeUnit;

    // Calculate progress ratios
    final hydrationRatio = hydrationGoal > 0
        ? (provider.hydrationCurrent / hydrationGoal).clamp(0.0, 1.0)
        : 0.0;
    final caffeineRatio = caffeineLimit > 0
        ? (provider.caffeineCurrent / caffeineLimit).clamp(0.0, 1.0)
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
                  // Hydration progress bar
                  const Text(
                    'Hydration',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: hydrationRatio,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      '${provider.hydrationCurrent.toStringAsFixed(1)} / '
                      '$hydrationGoal $volumeUnit'),

                  const SizedBox(height: 16),

                  // Caffeine progress bar
                  const Text(
                    'Caffeine',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: caffeineRatio,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      provider.isNearCaffeineLimit ? Colors.red : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      '${provider.caffeineCurrent.toStringAsFixed(0)} / '
                      '$caffeineLimit mg'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==================== QUICK ADD SECTION ====================
            _buildQuickAddSection(favProvider),

            const SizedBox(height: 24),

            // Reset button (for testing)
            TextButton(
              onPressed: () {
                context.read<HydrationProvider>().resetDay();
              },
              child: const Text('Reset (Test)'),
            ),
          ],
        ),
      ),

      // ==================== BOTTOM NAVIGATION ====================
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushNamed(context, '/log');
              break;
            case 2:
              Navigator.pushNamed(context, '/goals');
              break;
            case 3:
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Goals'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  // Build Quick Add section
  Widget _buildQuickAddSection(FavoriteDrinksProvider favProvider) {
    final quickAdds = favProvider.quickAddFavorites;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Add',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/library');
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Empty state
          if (quickAdds.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      'No Quick Add drinks set',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/library');
                      },
                      icon: const Icon(Icons.star),
                      label: const Text('Add Favorites'),
                    ),
                  ],
                ),
              ),
            )
          // Quick Add buttons grid
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: quickAdds.length + 1, // +1 for "More" button
              itemBuilder: (context, index) {
                // Last item is "More" button
                if (index == quickAdds.length) {
                  return _buildQuickAddButton(
                    icon: Icons.add,
                    label: 'More',
                    onTap: _openDrinkLibrary,
                    isHighlighted: true,
                  );
                }

                // Quick Add buttons from favorites
                final favorite = quickAdds[index];
                return _buildFavoriteButton(favorite);
              },
            ),
        ],
      ),
    );
  }

  // Build favorite quick add button
  Widget _buildFavoriteButton(FavoriteDrink favorite) {
    // Icon mapping
    IconData icon = Icons.local_drink;
    if (favorite.customIcon == 'water_drop') icon = Icons.water_drop;
    if (favorite.customIcon == 'coffee') icon = Icons.coffee;
    if (favorite.customIcon == 'emoji_food_beverage') icon = Icons.emoji_food_beverage;
    if (favorite.customIcon == 'bolt') icon = Icons.bolt;

    // Get first word of beverage name
    final displayName = favorite.beverageName.split(' ').first;
    final volumeOz = favorite.customVolumeOz ?? 8.0;

    return _buildQuickAddButton(
      icon: icon,
      label: displayName,
      subtitle: '${volumeOz.toStringAsFixed(0)} oz',
      onTap: () => _quickAddDrink(favorite),
    );
  }

  // Build a single Quick Add button
  Widget _buildQuickAddButton({
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isHighlighted ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isHighlighted ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? Colors.white : Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isHighlighted ? Colors.white70 : Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }
}