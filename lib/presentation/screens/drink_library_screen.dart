import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

class _DrinkLibraryScreenState extends State<DrinkLibraryScreen>
    with SingleTickerProviderStateMixin {
  final BeverageDao dao = BeverageDao();
  List<Beverage> beverages = [];
  List<Beverage> filteredBeverages = [];
  bool isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadBeverages();
    _loadFavorites();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // 탭 전환 시 검색어 초기화
      if (_tabController.indexIsChanging) {
        _searchController.clear();
        setState(() {
          _searchQuery = '';
          filteredBeverages = beverages;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Fetch all beverages from the database
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

  // Load the user's favorite drinks
  Future<void> _loadFavorites() async {
    final provider = context.read<FavoriteDrinksProvider>();
    await provider.loadFavorites();
  }

  // Filter the beverage list based on the search query
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

  // Get the corresponding Material Icon based on the icon name string
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

    // Separate the filtered list into favorites and non-favorites
    final favoriteBeverages = filteredBeverages
        .where((bev) => favProvider.isFavorite(bev.name))
        .toList();

    return Scaffold(
        appBar: AppBar(
          title: const Text('Drink Library'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'All Drinks', icon: Icon(Icons.local_drink)),
              Tab(text: 'Favorites', icon: Icon(Icons.star)),
            ],
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        // A Floating Action Button replaces the old inline button for better UX
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showDrinkInput(context),
          icon: const Icon(Icons.add),
          label: const Text('Custom Drink'),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            // Static Search Bar at the top
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search drinks by name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  filled: true,
                  isDense: true,
                ),
                controller: _searchController,
                onChanged: _onSearchChanged,
              ),
            ),

            // The main content area that switches based on the selected tab
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // First Tab: All Drinks
                        _buildDrinkList(
                          filteredBeverages, 
                          favProvider, 
                          emptyMessage: 'No drinks match your search',
                        ),
                        // Second Tab: Favorites Only
                        _buildDrinkList(
                          favoriteBeverages, 
                          favProvider, 
                          emptyMessage: 'No favorites yet.\nTap the star to add some!',
                        ),
                      ],
                    ),
            ),
          ],
        ),
    );
  }

  // Helper method to build the list view for either tab
  Widget _buildDrinkList(
    List<Beverage> drinkList, 
    FavoriteDrinksProvider favProvider, {
    required String emptyMessage,
  }) {
    if (drinkList.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80), // Padding avoids overlap with FAB
      itemCount: drinkList.length,
      itemBuilder: (context, index) {
        final bev = drinkList[index];
        final favorite = favProvider.favorites
            .where((f) => f.beverageName == bev.name)
            .firstOrNull;
            
        return _buildBeverageCard(bev, favorite, favProvider);
      },
    );
  }

  // Builds the individual card for each beverage
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

  // Builds the star icon, including a small green badge if it's set to "Quick Add"
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

  // Toggles the favorite status of a beverage
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

  // Shows the dialog to edit display name, icon, volume, and quick add status
  Future<void> _showEditDialog(Beverage beverage, FavoriteDrink? favorite) async {
    final currentVolume = (favorite?.customVolumeOz ?? beverage.defaultVolumeOz).toDouble();
    final isQuickAdd = favorite?.isQuickAdd ?? false;

    final volumeController = TextEditingController(text: currentVolume.toString());

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
                        color: Theme.of(dialogContext).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.coffee, size: 20,
                              color: Theme.of(dialogContext).colorScheme.primary),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid volume')),
                      );
                      return;
                    }

                    // Not a favorite — nothing to save; just close
                    if (favorite == null) {
                      Navigator.pop(dialogContext);
                      return;
                    }

                    // Capture values before closing dialog
                    final capturedFavoriteId = favorite.id;
                    final capturedIcon = selectedIcon;
                    final capturedQuickAdd = tempQuickAdd;
                    final capturedIsQuickAdd = isQuickAdd;

                    // Close dialog FIRST before any async work to prevent
                    // _dependents.isEmpty assertion crash from notifyListeners()
                    // firing while the dialog context is still in the widget tree
                    Navigator.pop(dialogContext);

                    final favProvider = context.read<FavoriteDrinksProvider>();

                    await favProvider.updateFavorite(
                      id: capturedFavoriteId,
                      customIcon: capturedIcon,
                      customVolumeOz: vol,
                    );

                    if (capturedQuickAdd != capturedIsQuickAdd) {
                      await favProvider.toggleQuickAdd(capturedFavoriteId);
                    }

                    if (mounted) {
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
    } finally {
      volumeController.dispose();
    }
  }

  // Show and process the custom drink input dialog
  void _showDrinkInput(BuildContext context) async {
    final drink = await showDialog(
      context: context,
      builder: (context) => DrinkInput(),
    );

    if (drink != null) {
      String name = drink["name"];
      double size = drink["size"];
      double caff = drink["caff"];

      double caffPerOz = caff / size;
      double hydFac = switch (caffPerOz) {
        >= 60 => 0.6,
        >= 40 && < 60 => 0.65,
        >= 25 && < 40 => 0.7,
        >= 15 && < 25 => 0.75,
        >= 10 && < 15 => 0.8,
        >= 5 && < 10 => 0.85,
        >= 2 && < 5 => 0.9,
        > 0 && < 2 => 0.95,
        0 => 1.0,
        _ => 0.0
      };

      // Add data to Supabase
      await addDrink(size: size, hydFac: hydFac, caffPerOz: caffPerOz, name: name);
      
      // Refresh the list after adding (Important!)
      _loadBeverages();
    }
  }

}

// ------------------------------------------------------------------
// External functions and widgets for the Custom Drink feature
// ------------------------------------------------------------------

// Adds the custom drink to the Supabase database
Future<void> addDrink({
  required double size,
  required double hydFac,
  required double caffPerOz,
  required String name,
}) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  
  if (userId == null) return;

  await supabase.from('custom_beverages').insert({
    'user_id': userId,
    'name': name,
    'caffeine_per_oz': caffPerOz,
    'hydration_factor': hydFac,
    'default_volume_oz': size,
  });
}

// Dialog widget to input custom drink details
class DrinkInput extends StatefulWidget {
  @override
  _AddCustomDrink createState() => _AddCustomDrink();
}

class _AddCustomDrink extends State<DrinkInput> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _caffeineController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _caffeineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter your custom drink'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: "Drink name"),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter a drink name";
                }
                return null;
              },
            ),
            TextFormField(
              controller: _sizeController,
              decoration: const InputDecoration(hintText: "Drink size (oz)"),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter a drink size";
                }
                final size = double.tryParse(value);
                if (size == null) return "Please enter a number";
                if (size <= 0) return "Size must be greater than 0";
                return null;
              },
            ),
            TextFormField(
              controller: _caffeineController,
              decoration: const InputDecoration(hintText: "Caffeine content (mg)"),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter a caffeine amount";
                }
                final caff = double.tryParse(value);
                if (caff == null) return "Please enter a number";
                if (caff < 0) return "Caffeine cannot be negative";
                return null;
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
            _nameController.clear();
            _sizeController.clear();
            _caffeineController.clear();
          },
        ),
        TextButton(
          child: const Text("Submit"),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
                'size': double.parse(_sizeController.text),
                'caff': double.parse(_caffeineController.text)
              });
            }
          },
        )
      ],
    );
  }
}