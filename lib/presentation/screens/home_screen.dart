import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_card.dart';
import '../../data/dao/beverages_dao.dart';
import '../../data/models/beverage.dart';
import '../../application/providers/hydration_provider.dart';
import '../../application/providers/profile_provider.dart';
import '../../application/providers/favorite_drinks_provider.dart'; // Added!
import '../../data/models/favorite_drink.dart'; // Added!
import '../../business/services/ai_analysis_service.dart';
import '../../business/services/connectivity_service.dart';
import '../widgets/offline_banner.dart';

/// HomeScreen - Main screen showing hydration progress and quick add buttons
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BeverageDao dao = BeverageDao();
  String? _aiInsight;
  bool _aiLoading = false;

  VoidCallback? _connectivityListener;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileProvider = context.read<ProfileProvider>();
      final hydrationProvider = context.read<HydrationProvider>();
      final favProvider = context.read<FavoriteDrinksProvider>(); // Added!
      final connectivity = context.read<ConnectivityService>();

      // 온라인 복귀 시 대기 중인 로그 자동 sync
      _connectivityListener = () {
        if (connectivity.isOnline) {
          context.read<HydrationProvider>().syncPendingLogs();
        }
      };
      connectivity.addListener(_connectivityListener!);

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

  @override
  void dispose() {
    // Remove connectivity listener to prevent _dependents.isEmpty assertion crash
    if (_connectivityListener != null) {
      context.read<ConnectivityService>().removeListener(_connectivityListener!);
    }
    super.dispose();
  }

  Future<void> _fetchAiInsight() async {
    final provider = context.read<HydrationProvider>();
    final profileProvider = context.read<ProfileProvider>();

    setState(() {
      _aiLoading = true;
      _aiInsight = null;
    });

    try {
      // Weekly average (last 7 days)
      final now = DateTime.now();
      double weeklyTotalPercent = 0;
      int daysWithData = 0;
      final goal = profileProvider.dailyHydrationGoalOz.toDouble();

      for (int i = 1; i <= 7; i++) {
        final day = now.subtract(Duration(days: i));
        final logs = provider.getLogsBetween(day, day);
        if (logs.isNotEmpty) {
          final dayOz = logs.fold<double>(
              0, (sum, l) => sum + ((l['actualHydrationOz'] as double?) ?? 0));
          weeklyTotalPercent += goal > 0 ? (dayOz / goal * 100) : 0;
          daysWithData++;
        }
      }
      final weeklyAvg = daysWithData > 0 ? weeklyTotalPercent / daysWithData : 0.0;

      // Top drink today
      final drinkCount = <String, int>{};
      for (final log in provider.todayLogs) {
        final name = (log['beverageName'] as String?) ?? 'Unknown';
        drinkCount[name] = (drinkCount[name] ?? 0) + 1;
      }
      final topDrink = drinkCount.isEmpty
          ? 'None'
          : (drinkCount.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;

      // Drinking time pattern
      final hours = provider.todayLogs
          .map((l) => DateTime.tryParse(l['timestamp'] as String? ?? '')?.hour)
          .whereType<int>()
          .toList();
      String pattern = 'spread';
      if (hours.isNotEmpty) {
        final avg = hours.reduce((a, b) => a + b) / hours.length;
        if (avg < 10) pattern = 'morning';
        else if (avg < 14) pattern = 'midday';
        else if (avg < 18) pattern = 'afternoon';
        else pattern = 'evening';
      }

      final insight = await AiAnalysisService.analyzeTodayHydration(
        currentOz: provider.hydrationCurrent,
        goalOz: goal,
        caffeineMg: provider.caffeineCurrent,
        caffeineLimitMg: profileProvider.dailyCaffeineLimitMg.toDouble(),
        logCount: provider.logCount,
        streak: provider.currentStreak,
        weeklyAvgPercent: weeklyAvg,
        topDrink: topDrink,
        drinkingPattern: pattern,
        uniqueDrinkTypes: provider.uniqueDrinkTypesToday,
      );
      setState(() => _aiInsight = insight);
    } catch (e) {
      debugPrint('AI error: $e');
      setState(() => _aiInsight = 'Could not load insight. Please try again.');
    } finally {
      setState(() => _aiLoading = false);
    }
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

    final hydrationGoal = profileProvider.dailyGoalInPreferredUnit;
    final caffeineLimit = profileProvider.dailyCaffeineLimitMg;
    final volumeUnit = profileProvider.preferredVolumeUnit;

    final hydrationCurrent = volumeUnit == 'ml'
        ? provider.hydrationCurrent * 29.5735
        : provider.hydrationCurrent;

    // Calculate progress ratios
    final hydrationRatio = hydrationGoal > 0
        ? (hydrationCurrent / hydrationGoal).clamp(0.0, 1.0)
        : 0.0;
    final caffeineRatio = caffeineLimit > 0
        ? (provider.caffeineCurrent / caffeineLimit).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HydraTrack'),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: SingleChildScrollView(
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

            // ==================== AI ANALYSIS ====================
            _buildAiCard(),

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
                      '${hydrationCurrent.toStringAsFixed(1)} / '
                      '${hydrationGoal.toStringAsFixed(1)} $volumeUnit'),

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
          ],
        ),
      )),
        ],
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
              Navigator.pushNamed(context, '/alchome');
              break;
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

  Widget _buildAiCard() {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Insight',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_aiLoading)
            const Center(child: CircularProgressIndicator())
          else if (_aiInsight != null)
            Text(_aiInsight!, style: const TextStyle(fontSize: 14))
          else
            Text(
              'Tap below to get a personalized hydration tip.',
              style: TextStyle(color: colors.onSurface.withOpacity(0.6), fontSize: 14),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _aiLoading ? null : _fetchAiInsight,
              child: const Text('Analyze My Hydration'),
            ),
          ),
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
                  Navigator.pushNamed(context, '/manage-quick-add');
                },
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Manage'),
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

    // Get first word of effective name (uses displayName if set, else beverageName)
    final displayName = favorite.effectiveName.split(' ').first;
    final volumeOz = favorite.customVolumeOz ?? 8.0;

    final profileProvider = context.read<ProfileProvider>();
    final unit = profileProvider.preferredVolumeUnit;
    final displayVolume = unit == 'ml' ? volumeOz * 29.5735 : volumeOz;

    return _buildQuickAddButton(
      icon: icon,
      label: displayName,
      subtitle: '${displayVolume.toStringAsFixed(0)} $unit',
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