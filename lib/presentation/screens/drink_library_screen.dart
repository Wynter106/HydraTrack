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
      setState(() => isLoading = false);
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
    await provider.loadFavorites();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();
      filteredBeverages = _searchQuery.isEmpty
          ? beverages
          : beverages.where((bev) {
              return bev.name.toLowerCase().contains(_searchQuery);
            }).toList();
    });
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'water_drop': return Icons.water_drop;
      case 'coffee': return Icons.coffee;
      case 'emoji_food_beverage': return Icons.emoji_food_beverage;
      case 'bolt': return Icons.bolt;
      case 'local_bar': return Icons.local_bar;
      default: return Icons.local_drink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoriteDrinksProvider>();

    final favoriteBeverages = filteredBeverages
        .where((bev) => favProvider.isFavorite(bev.name))
        .toList();
    final nonFavoriteBeverages = filteredBeverages
        .where((bev) => !favProvider.isFavorite(bev.name))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Drink Library')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Browse available drinks',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 16),

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

            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (beverages.isEmpty)
              const Expanded(child: Center(child: Text('No drinks found in database')))
            else if (filteredBeverages.isEmpty)
              const Expanded(child: Center(child: Text('No drinks match your search')))
            else
              Expanded(
                child: ListView(
                  children: [
                    if (favoriteBeverages.isNotEmpty) ...[
                      _buildSectionHeader('Favorites ★'),
                      ...favoriteBeverages.map((bev) {
                        final favorite = favProvider.favorites
                            .where((f) => f.beverageName == bev.name)
                            .firstOrNull;
                        return _buildBeverageCard(bev, favorite, favProvider);
                      }),
                      const SizedBox(height: 8),
                    ],
                    _buildSectionHeader('All Drinks'),
                    ...nonFavoriteBeverages.map((bev) {
                      return _buildBeverageCard(bev, null, favProvider);
                    }),
                  ],
                ),
              ),

            const SizedBox(height: 12),
            AppButton(
              label: 'Back to Home',
              filled: false,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildBeverageCard(
    Beverage beverage,
    FavoriteDrink? favorite,
    FavoriteDrinksProvider favProvider,
  ) {
    final totalCaffeine = beverage.caffeinePerOz * beverage.defaultVolumeOz;
    final isFavorite = favProvider.isFavorite(beverage.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: ListTile(
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
          trailing: IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _showEditDialog(beverage, favorite),
          ),
          onTap: () => Navigator.pop(context, beverage),
        ),
      ),
    );
  }

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
            Center(
              child: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : Colors.grey,
                size: 32,
              ),
            ),
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

  Future<void> _showEditDialog(Beverage beverage, FavoriteDrink? favorite) async {
    final currentVolume = (favorite?.customVolumeOz ?? beverage.defaultVolumeOz).toDouble();
    final isQuickAdd = favorite?.isQuickAdd ?? false;

    final volumeController = TextEditingController(text: currentVolume.toString());
    final displayNameController = TextEditingController(
      text: favorite?.displayName ?? '',
    );

    bool tempQuickAdd = isQuickAdd;
    double tempVolume = currentVolume;
    String? selectedIcon = favorite?.customIcon ?? 'local_drink';

    try {
      await showDialog(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final calculatedCaffeine = beverage.caffeinePerOz * tempVolume;

            return AlertDialog(
              title: Text('Edit ${beverage.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: displayNameController,
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        hintText: beverage.name,
                        helperText: 'Name shown on Quick Add button',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedIcon,
                      decoration: const InputDecoration(
                        labelText: 'Icon',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'local_drink',
                          child: Row(children: [
                            Icon(_getIcon('local_drink')),
                            const SizedBox(width: 8),
                            const Text('Default'),
                          ]),
                        ),
                        DropdownMenuItem(
                          value: 'water_drop',
                          child: Row(children: [
                            Icon(_getIcon('water_drop')),
                            const SizedBox(width: 8),
                            const Text('Water'),
                          ]),
                        ),
                        DropdownMenuItem(
                          value: 'coffee',
                          child: Row(children: [
                            Icon(_getIcon('coffee')),
                            const SizedBox(width: 8),
                            const Text('Coffee'),
                          ]),
                        ),
                        DropdownMenuItem(
                          value: 'emoji_food_beverage',
                          child: Row(children: [
                            Icon(_getIcon('emoji_food_beverage')),
                            const SizedBox(width: 8),
                            const Text('Tea'),
                          ]),
                        ),
                        DropdownMenuItem(
                          value: 'bolt',
                          child: Row(children: [
                            Icon(_getIcon('bolt')),
                            const SizedBox(width: 8),
                            const Text('Energy'),
                          ]),
                        ),
                        DropdownMenuItem(
                          value: 'local_bar',
                          child: Row(children: [
                            Icon(_getIcon('local_bar')),
                            const SizedBox(width: 8),
                            const Text('Alcohol'),
                          ]),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() => selectedIcon = value);
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: volumeController,
                      decoration: const InputDecoration(
                        labelText: 'Volume',
                        suffixText: 'oz',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        final vol = double.tryParse(value);
                        if (vol != null && vol > 0) {
                          setDialogState(() => tempVolume = vol);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (favorite != null)
                      SwitchListTile(
                        title: const Text('Add to Quick Add'),
                        subtitle: const Text('Show on home screen'),
                        value: tempQuickAdd,
                        onChanged: (value) {
                          setDialogState(() => tempQuickAdd = value);
                        },
                      ),

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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final vol = double.tryParse(volumeController.text);
                    if (vol == null || vol <= 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid volume')),
                      );
                      return;
                    }

                    final newDisplayName = displayNameController.text.trim().isEmpty
                        ? null
                        : displayNameController.text.trim();

                    final favProvider = dialogContext.read<FavoriteDrinksProvider>();

                    if (favorite != null) {
                      await favProvider.updateFavorite(
                        id: favorite.id,
                        displayName: newDisplayName,
                        customIcon: selectedIcon,
                        customVolumeOz: vol,
                      );

                      if (tempQuickAdd != isQuickAdd) {
                        await favProvider.toggleQuickAdd(favorite.id);
                      }
                    } else {
                      await favProvider.addFavorite(
                        beverageName: beverage.name,
                        displayName: newDisplayName,
                        customIcon: selectedIcon,
                        customVolumeOz: vol,
                        isQuickAdd: false,
                      );
                    }

                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('${beverage.name} updated'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      volumeController.dispose();
      displayNameController.dispose();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}