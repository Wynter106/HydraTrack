import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_card.dart';
import '../../data/dao/beverages_dao.dart';
import '../../data/models/beverage.dart';
import '../../application/providers/hydration_provider.dart';
import '../../application/providers/profile_provider.dart';

/// HomeScreen - Main screen showing hydration progress and quick add buttons
/// 
/// This screen:
/// - Displays today's hydration and caffeine progress
/// - Provides Quick Add buttons for common drinks
/// - Uses Provider to share data with other screens
/// - Updates automatically when Provider data changes
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Database access for beverages
  final BeverageDao dao = BeverageDao();

  @override
  void initState() {
    super.initState();
    _checkDatabase(); 

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final profileProvider = context.read<ProfileProvider>();
    final hydrationProvider = context.read<HydrationProvider>();
    
    await profileProvider.loadProfile();
    
    hydrationProvider.setHydrationGoal(profileProvider.dailyHydrationGoalOz.toDouble());
    hydrationProvider.setCaffeineLimit(profileProvider.dailyCaffeineLimitMg.toDouble());
    
    await hydrationProvider.loadTodayLogs();
    });
  }

  /// Check what's in database (for debugging)
  /// TODO: Remove after testing
  Future<void> _checkDatabase() async {
    debugPrint('=== Checking Database ===');
    final results = await dao.searchBeverages('Water');
    debugPrint('Found ${results.length} results for "Water":');
    for (var bev in results) {
      debugPrint('  - "${bev.name}"');
    }
    debugPrint('=========================');
  }

  /// Quick Add default drinks
  /// These names must match exactly with database entries
  /// TODO: Make this customizable in Settings
  final List<Map<String, dynamic>> quickAddItems = [
    {
      'name': 'Water',
      'icon': Icons.water_drop,
      'dbName': 'Water',
      'volumeOz': 8.0,
    },
    {
      'name': 'Coffee',
      'icon': Icons.coffee,
      'dbName': 'Coffee',
      'volumeOz': 8.0,
    },
    {
      'name': 'Tea',
      'icon': Icons.emoji_food_beverage,
      'dbName': 'Tea (Green)',
      'volumeOz': 8.0,
    },
    {
      'name': 'Soda',
      'icon': Icons.local_drink,
      'dbName': 'Coca-Cola Classic',
      'volumeOz': 12.0,
    },
    {
      'name': 'Energy',
      'icon': Icons.bolt,
      'dbName': 'Red Bull',
      'volumeOz': 8.0,
    },
  ];

  /// Adds a drink from Quick Add button
  /// 
  /// Flow:
  /// 1. Find beverage in database by exact name
  /// 2. Call Provider.addDrink() with beverage and volume
  /// 3. Provider calculates hydration/caffeine and stores it
  /// 4. All screens update automatically
  Future<void> _addQuickDrink(String dbName, double volumeOz) async {
    try {
      // Find beverage in database
      final beverage = await dao.getBeverageByExactName(dbName);
      
      if (beverage == null) {
        debugPrint('Error: Beverage not found: $dbName');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Drink not found: $dbName')),
        );
        return;
      }
      
      // Add to Provider (listen: false because we're in a callback)
      final provider = Provider.of<HydrationProvider>(context, listen: false);
      await provider.addDrink(beverage, volumeOz: volumeOz);
      
    } catch (e) {
      debugPrint('Error adding drink: $e');
    }
  }

  /// Opens DrinkLibrary and handles selected beverage
  /// 
  /// Flow:
  /// 1. Open DrinkLibrary screen
  /// 2. Wait for user to select a drink
  /// 3. DrinkLibrary returns beverage via Navigator.pop()
  /// 4. Add beverage to Provider
  Future<void> _openDrinkLibrary() async {
    // Wait for user to select a drink
    final selectedBeverage = await Navigator.pushNamed(context, '/library');
    
    // If user selected something (not just pressed back)
    if (selectedBeverage != null && selectedBeverage is Beverage) {
      // Add to Provider
      final provider = Provider.of<HydrationProvider>(context, listen: false);
      await provider.addDrink(selectedBeverage);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch Provider for changes - rebuilds when data changes
    final provider = Provider.of<HydrationProvider>(context);
    final profileProvider = context.watch<ProfileProvider>();

    final hydrationGoal = profileProvider.dailyHydrationGoalOz;  
    final caffeineLimit = profileProvider.dailyCaffeineLimitMg;
    final volumeUnit = profileProvider.preferredVolumeUnit;

    // Calculate progress ratios (clamped to 0-1 range)
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
                    '$hydrationGoal $volumeUnit'
                  ),

                  const SizedBox(height: 16),

                  // Caffeine progress bar (turns red when near limit)
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
                    '$caffeineLimit mg'
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==================== QUICK ADD SECTION ====================
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Add',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 3x2 grid of drink buttons
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      // Quick add drink buttons
                      ...quickAddItems.map((item) => _buildQuickAddButton(
                        icon: item['icon'] as IconData,
                        label: item['name'] as String,
                        onTap: () => _addQuickDrink(
                          item['dbName'] as String,
                          item['volumeOz'] as double,
                        ),
                      )),
                      
                      // "More" button opens DrinkLibrary
                      _buildQuickAddButton(
                        icon: Icons.add,
                        label: 'More',
                        onTap: _openDrinkLibrary,
                        isHighlighted: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Reset button (for testing)
            // TODO: Remove before production release
            TextButton(
              onPressed: () {
                Provider.of<HydrationProvider>(context, listen: false).resetDay();
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
              // Already on Home
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

  /// Builds a single Quick Add button
  Widget _buildQuickAddButton({
    required IconData icon,
    required String label,
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
                color: isHighlighted ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}