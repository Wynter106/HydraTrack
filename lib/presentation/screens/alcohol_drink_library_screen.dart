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
      final result = await dao.getAllAlcoholicBeverages();
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

    final favoriteBeverages = filteredBeverages
        .where((bev) => favProvider.isFavorite(bev.name, isAlcoholList: true))
        .toList();

    return DefaultTabController(
      length: 2,
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showDrinkInput(context),
          icon: const Icon(Icons.add),
          label: const Text('Custom Drink'),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
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
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _buildDrinkList(
                          filteredBeverages,
                          favProvider,
                          emptyMessage: 'No drinks match your search',
                        ),
                        _buildDrinkList(
                          favoriteBeverages,
                          favProvider,
                          emptyMessage:
                              'No favorites yet.\nTap the star to add some!',
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

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
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
      itemCount: drinkList.length,
      itemBuilder: (context, index) {
        final bev = drinkList[index];
        final favorite = favProvider.alcoholFavorites
            .where((f) => f.beverageName == bev.name)
            .firstOrNull;

        return _buildBeverageCard(bev, favorite, favProvider);
      },
    );
  }

  Widget _buildBeverageCard(
    Beverage beverage,
    FavoriteDrink? favorite,
    FavoriteDrinksProvider favProvider,
  ) {
    final isFavorite = favProvider.isFavorite(
      beverage.name,
      isAlcoholList: true,
    );

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
    final added = await favProvider.toggleFavorite(
      beverageName,
      isAlcoholList: true,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added
                ? '$beverageName added to alcohol favorites'
                : '$beverageName removed from alcohol favorites',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _showEditDialog(
      Beverage beverage, FavoriteDrink? favorite) async {
    final currentVolume =
        (favorite?.customVolumeOz ?? beverage.defaultVolumeOz).toDouble();
    final isQuickAdd = favorite?.isQuickAdd ?? false;

    final volumeController =
        TextEditingController(text: currentVolume.toString());

    bool tempQuickAdd = isQuickAdd;
    double tempVolume = currentVolume;
    String? selectedIcon = favorite?.customIcon ?? 'local_bar';

    try {
      await showDialog(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text('Edit ${beverage.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Icon picker ──────────────────────────────────
                    DropdownButtonFormField<String>(
                      value: selectedIcon,
                      decoration: const InputDecoration(
                        labelText: 'Icon',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'local_bar',
                          child: Row(children: [
                            Icon(_getIcon('local_bar')),
                            const SizedBox(width: 8),
                            const Text('Alcohol'),
                          ]),
                        ),
                        DropdownMenuItem(
                          value: 'local_drink',
                          child: Row(children: [
                            Icon(_getIcon('local_drink')),
                            const SizedBox(width: 8),
                            const Text('Drink'),
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
                      ],
                      onChanged: (value) {
                        setDialogState(() => selectedIcon = value);
                      },
                    ),
                    const SizedBox(height: 12),

                    // ── Volume ───────────────────────────────────────
                    TextField(
                      controller: volumeController,
                      decoration: const InputDecoration(
                        labelText: 'Volume',
                        suffixText: 'oz',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        final vol = double.tryParse(value);
                        if (vol != null && vol > 0) {
                          setDialogState(() => tempVolume = vol);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // ── ABV info (read-only display) ─────────────────
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_bar,
                              size: 20, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'ABV: ${beverage.abv?.toStringAsFixed(1) ?? "—"}%  '
                            '· ${beverage.standardDrinks(volumeOz: tempVolume).toStringAsFixed(2)} std drinks',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Quick Add toggle (only if already a favorite) ─
                    if (favorite != null)
                      SwitchListTile(
                        title: const Text('Add to Quick Add'),
                        subtitle:
                            const Text('Show on alcohol screen'),
                        value: tempQuickAdd,
                        activeColor: Colors.orange,
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
                        const SnackBar(
                            content: Text('Please enter a valid volume')),
                      );
                      return;
                    }

                    final favProvider =
                        dialogContext.read<FavoriteDrinksProvider>();

                    if (favorite != null) {
                      // Update existing favorite
                      await favProvider.updateFavorite(
                        id: favorite.id,
                        customIcon: selectedIcon,
                        customVolumeOz: vol,
                      );

                      if (tempQuickAdd != isQuickAdd) {
                        await favProvider.toggleQuickAdd(favorite.id);
                      }
                    } else {
                      // Add as new favorite — no display name, just the drink name
                      await favProvider.addFavorite(
                        beverageName: beverage.name,
                        customIcon: selectedIcon,
                        customVolumeOz: vol,
                        isQuickAdd: false,
                        isAlcoholList: true,
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
    }
  }

  void _showDrinkInput(BuildContext context) async {
    final drink = await showDialog(
      context: context,
      builder: (context) => DrinkInput(),
    );

    if (drink != null) {
      String name = drink["name"];
      double size = drink["size"];
      double alcoholpercentage = drink["alcohol"];

      await addDrink(
        size: size,
        abvPercent: alcoholpercentage,
        name: name,
      );

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

Future<void> addDrink({
  required double size,
  required double abvPercent,
  required String name,
}) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  await supabase.from('custom_beverages').insert({
    'user_id': userId,
    'name': name,
    'abv': abvPercent,
    'default_volume_oz': size,
    'is_alcoholic': true,
    'hydration_factor': -0.5,
    'caffeine_per_oz': 0.0,
  });
}

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
            TextFormField(
              controller: _alcoholController,
              decoration:
                  const InputDecoration(hintText: "Alcohol content (%)"),
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
                'alcohol': double.parse(_alcoholController.text),
              });
            }
          },
        ),
      ],
    );
  }
}