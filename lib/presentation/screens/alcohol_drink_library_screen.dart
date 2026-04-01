import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../../data/dao/beverages_dao.dart';
import '../../data/models/beverage.dart';
import '../../application/providers/favorite_drinks_provider.dart';
import '../../data/models/favorite_drink.dart';

class AlcoholDrinkLibraryScreen extends StatefulWidget {
  const AlcoholDrinkLibraryScreen({super.key});

  @override
  State<AlcoholDrinkLibraryScreen> createState() => _DrinkLibraryScreenState();
}

class _DrinkLibraryScreenState extends State<AlcoholDrinkLibraryScreen> {
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

  // Fetch all beverages from the database
  Future<void> _loadBeverages() async {
  try {
    final result = await dao.getAllAlcoholicBeverages(); // ← was getAllBeverages()
    setState(() {
      beverages = result;
      filteredBeverages = result;
      isLoading = false;
    });
  } catch (e) {
    setState(() => isLoading = false);
    debugPrint('Error loading beverages: $e');
  }
}

// Use the alcohol-specific search
void _onSearchChanged(String value) async {
  final query = value.trim().toLowerCase();
  setState(() => _searchQuery = query);

  if (query.isEmpty) {
    setState(() => filteredBeverages = beverages);
    return;
  }

  // Search Supabase directly for better results
  final results = await dao.searchAlcoholicBeverages(query);
  if (mounted) setState(() => filteredBeverages = results);
}

  // Load the user's favorite drinks
  Future<void> _loadFavorites() async {
    final provider = context.read<FavoriteDrinksProvider>();
    await provider.loadFavorites();
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

    // DefaultTabController enables the TabBar and TabBarView to sync automatically
    return DefaultTabController(
      length: 2, // We have two tabs: All Drinks and Favorites
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Alcoholic Drink Library'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All Drinks', icon: Icon(Icons.local_drink)),
              Tab(text: 'Favorites', icon: Icon(Icons.star)),
            ],
            indicatorColor: Colors.blueAccent,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
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
                  fillColor: Colors.white,
                  isDense: true,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            
            // The main content area that switches based on the selected tab
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
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
            'Serving: ${beverage.defaultVolumeOz} oz  '
            '· ABV: ${beverage.abv?.toStringAsFixed(1) ?? "—"}%\n'
            '${beverage.standardDrinks().toStringAsFixed(2)} standard drinks per serving',
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
                            'Alcohol: 300 mg',                                   //Change once db is implemented
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

  // Show and process the custom drink input dialog
  void _showDrinkInput(BuildContext context) async {        //Change once db is implemented
    final drink = await showDialog(
      context: context,
      builder: (context) => DrinkInput(),
    );

    if (drink != null) {
      String name = drink["name"];
      double size = drink["size"];
      double alcoholpercentage = drink["alcohol"];

      double alcohol = alcoholpercentage * size;

      // Add data to Supabase
      await addDrink(size: size, alcohol: alcohol, name: name);
      
      // Refresh the list after adding (Important!)
      _loadBeverages();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// ------------------------------------------------------------------
// External functions and widgets for the Custom Drink feature
// ------------------------------------------------------------------

// Adds the custom drink to the Supabase database
Future<void> addDrink({
  required double size,
  required double alcohol, // ABV percentage entered by user
  required String name,
}) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  await supabase.from('custom_beverages').insert({
    'user_id': userId,
    'name': name,
    'abv': alcohol,
    'default_volume_oz': size,
    'is_alcoholic': true,
    'hydration_factor': -0.5,
    'caffeine_per_oz': 0.0,
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
  final TextEditingController _alcoholController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _alcoholController.dispose();
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
                if (value == null || value.isEmpty) {
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
                if (value == null || value.isEmpty) {
                  return "Please enter a drink size";
                } else {
                  double? size = double.tryParse(value);
                  if (size == null) {
                    return "Please enter a number";
                  }
                }
                return null;
              },
            ),
            TextFormField(                         //Does alcohol instead of caffeine
              controller: _alcoholController,
              decoration: const InputDecoration(hintText: "Alcohol content (%)"),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter an alcohol amount";
                } else {
                  double? caff = double.tryParse(value);
                  if (caff == null) {
                    return "Please enter a number";
                  }
                }
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
            _alcoholController.clear();
          },
        ),
        TextButton(
          child: const Text("Submit"),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text,
                'size': double.parse(_sizeController.text),
                'alcohol': double.parse(_alcoholController.text)
              });
            }
          },
        )
      ],
    );
  }
}