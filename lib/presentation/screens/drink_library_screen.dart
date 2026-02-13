import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../../data/dao/beverages_dao.dart';
import '../../data/models/beverage.dart';
import '../../application/providers/favorite_drinks_provider.dart';
import '../../data/models/favorite_drink.dart';

class DrinkLibraryScreen extends StatefulWidget {
  const DrinkLibraryScreen({super.key});

  @override
  State<DrinkLibraryScreen> createState() => _DrinkLibraryScreenState();
}

class _DrinkLibraryScreenState extends State<DrinkLibraryScreen> {
  final BeverageDao dao = BeverageDao();
  List<Beverage> beverages = [];
  List<Beverage> filteredBeverages = [];
  bool isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBeverages();
    _loadFavorites();
  }

  Future<void> _loadBeverages() async {
    try {
      final result = await dao.getAllBeverages();
      setState(() {
        beverages = result;
        filteredBeverages = result;
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

  Future<void> _loadFavorites() async {
    final provider = context.read<FavoriteDrinksProvider>();
    // Don't call initializeDefaults here - only in home_screen!
    await provider.loadFavorites();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();

      if (_searchQuery.isEmpty) {
        filteredBeverages = beverages;
      } else {
        filteredBeverages = beverages.where((bev) {
          final name = bev.name.toLowerCase();
          return name.contains(_searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoriteDrinksProvider>();

    // Sort: favorites first, then non-favorites
    final favoriteBeverages = filteredBeverages
        .where((bev) => favProvider.isFavorite(bev.name))
        .toList();

    final nonFavoriteBeverages = filteredBeverages
        .where((bev) => !favProvider.isFavorite(bev.name))
        .toList();

    final sortedBeverages = [...favoriteBeverages, ...nonFavoriteBeverages];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drink Library'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top info
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Browse available drinks',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search drinks by name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                isDense: true,
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),

            // Beverage List
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
            else if (filteredBeverages.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No drinks match your search'),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: sortedBeverages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final beverage = sortedBeverages[index];
                    final totalCaffeine =
                        beverage.caffeinePerOz * beverage.defaultVolumeOz;
                    final isFavorite = favProvider.isFavorite(beverage.name);

                    // Get favorite object if exists
                    final favorite = favProvider.favorites
                        .where((fav) => fav.beverageName == beverage.name)
                        .firstOrNull;

                    return AppCard(
                      child: ListTile(
                        // Star icon with Quick Add badge
                        leading: _buildStarWithBadge(
                          isFavorite: isFavorite,
                          isQuickAdd: favorite?.isQuickAdd ?? false,
                          onStarPressed: () => _toggleFavorite(beverage.name),
                        ),
                        title: Text(beverage.name),
                        subtitle: Text(
                          'Volume: ${beverage.defaultVolumeOz.toStringAsFixed(1)} oz\n'
                          'Caffeine: ${totalCaffeine.toStringAsFixed(0)} mg  |  '
                          'Hydration: ${beverage.hydrationFactor.toStringAsFixed(2)}x',
                        ),
                        isThreeLine: true,
                        // Edit button for all beverages
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditDialog(beverage, favorite),
                        ),
                        // Tap to select beverage (original behavior)
                        onTap: () {
                          Navigator.pop(context, beverage);
                        },
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),

            // Back button
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

  // Star icon with Quick Add badge
  Widget _buildStarWithBadge({
    required bool isFavorite,
    required bool isQuickAdd,
    required VoidCallback onStarPressed,
  }) {
    return GestureDetector(
      onTap: onStarPressed,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          children: [
            // Star icon
            Center(
              child: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : Colors.grey,
                size: 32,
              ),
            ),
            // Quick Add badge (green dot)
            if (isFavorite && isQuickAdd)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Toggle favorite
  Future<void> _toggleFavorite(String beverageName) async {
    final favProvider = context.read<FavoriteDrinksProvider>();
    final added = await favProvider.toggleFavorite(beverageName);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added
                ? '$beverageName added to favorites'
                : '$beverageName removed from favorites',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // Edit dialog for volume/caffeine/quick add
  Future<void> _showEditDialog(Beverage beverage, FavoriteDrink? favorite) async {
    // Get current values - FIX: Cast to double explicitly
    final currentVolume = (favorite?.customVolumeOz ?? beverage.defaultVolumeOz).toDouble();
    final isQuickAdd = favorite?.isQuickAdd ?? false;

    final volumeController = TextEditingController(
      text: currentVolume.toString(),
    );

    bool tempQuickAdd = isQuickAdd;
    double tempVolume = currentVolume;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Calculate caffeine based on current volume
          final calculatedCaffeine = beverage.caffeinePerOz * tempVolume;

          return AlertDialog(
            title: Text('Edit ${beverage.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Volume input
                TextField(
                  controller: volumeController,
                  decoration: const InputDecoration(
                    labelText: 'Volume',
                    suffixText: 'oz',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    final volume = double.tryParse(value);
                    if (volume != null && volume > 0) {
                      setDialogState(() {
                        tempVolume = volume;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Calculated caffeine display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.coffee, size: 20, color: Colors.brown),
                      const SizedBox(width: 8),
                      Text(
                        'Caffeine: ${calculatedCaffeine.toStringAsFixed(0)} mg',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Add toggle (only if favorited)
                if (favorite != null)
                  SwitchListTile(
                    title: const Text('Add to Quick Add'),
                    subtitle: const Text('Show on home screen'),
                    value: tempQuickAdd,
                    onChanged: (value) {
                      setDialogState(() {
                        tempQuickAdd = value;
                      });
                    },
                  ),

                // Note if not favorited
                if (favorite == null)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Add to favorites (★) to enable Quick Add',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final volume = double.tryParse(volumeController.text);
                  if (volume == null || volume <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid volume')),
                    );
                    return;
                  }

                  final favProvider = context.read<FavoriteDrinksProvider>();

                  if (favorite != null) {
                    // Update existing favorite
                    await favProvider.updateFavorite(
                      id: favorite.id,
                      customVolumeOz: volume,
                    );

                    // Update Quick Add if changed
                    if (tempQuickAdd != isQuickAdd) {
                      await favProvider.toggleQuickAdd(favorite.id);
                    }
                  } else {
                    // Not favorited - add to favorites with custom volume
                    await favProvider.addFavorite(
                      beverageName: beverage.name,
                      customVolumeOz: volume,
                      isQuickAdd: false,
                    );
                  }

                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${beverage.name} updated'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    volumeController.dispose();
  }

  @override
  void dispose() {
    super.dispose();
  }
}