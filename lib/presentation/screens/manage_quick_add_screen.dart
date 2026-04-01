import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/providers/favorite_drinks_provider.dart';
import '../../data/models/favorite_drink.dart';

class ManageQuickAddScreen extends StatelessWidget {
  const ManageQuickAddScreen({super.key});

  static const _icons = {
    'local_drink': Icons.local_drink,
    'water_drop': Icons.water_drop,
    'coffee': Icons.coffee,
    'emoji_food_beverage': Icons.emoji_food_beverage,
    'bolt': Icons.bolt,
    'local_bar': Icons.local_bar,
  };

  static const _iconLabels = {
    'local_drink': 'Default',
    'water_drop': 'Water',
    'coffee': 'Coffee',
    'emoji_food_beverage': 'Tea',
    'bolt': 'Energy',
    'local_bar': 'Alcohol',
  };

  IconData _icon(String? key) => _icons[key] ?? Icons.local_drink;

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoriteDrinksProvider>();
    final favorites = favProvider.favorites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Quick Add'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/library'),
            icon: const Icon(Icons.add),
            label: const Text('Add Drinks'),
          ),
        ],
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_border, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No favorite drinks yet.',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/library'),
                    icon: const Icon(Icons.add),
                    label: const Text('Browse Drink Library'),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: favorites.length,
              onReorder: (oldIndex, newIndex) {
                context.read<FavoriteDrinksProvider>().reorderFavorites(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final fav = favorites[index];
                return _FavoriteTile(
                  key: ValueKey(fav.id),
                  favorite: fav,
                  iconData: _icon(fav.customIcon),
                  icons: _icons,
                  iconLabels: _iconLabels,
                );
              },
            ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  final FavoriteDrink favorite;
  final IconData iconData;
  final Map<String, IconData> icons;
  final Map<String, String> iconLabels;

  const _FavoriteTile({
    super.key,
    required this.favorite,
    required this.iconData,
    required this.icons,
    required this.iconLabels,
  });

  void _showEditDialog(BuildContext context) {
    final volController = TextEditingController(
        text: (favorite.customVolumeOz ?? 8.0).toStringAsFixed(1));
    final nameController = TextEditingController(
        text: favorite.displayName ?? '');
    String selectedIcon = favorite.customIcon ?? 'local_drink';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit ${favorite.beverageName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    hintText: favorite.beverageName,
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
                  items: icons.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Row(children: [
                              Icon(e.value),
                              const SizedBox(width: 8),
                              Text(iconLabels[e.key] ?? e.key),
                            ]),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedIcon = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: volController,
                  decoration: const InputDecoration(
                    labelText: 'Volume',
                    suffixText: 'oz',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final vol = double.tryParse(volController.text);
                final provider = context.read<FavoriteDrinksProvider>();
                await provider.updateFavorite(
                  id: favorite.id,
                  displayName: nameController.text.trim().isEmpty
                      ? null
                      : nameController.text.trim(),
                  customIcon: selectedIcon,
                  customVolumeOz: (vol != null && vol > 0) ? vol : null,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final vol = favorite.customVolumeOz ?? 8.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: favorite.isQuickAdd
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
          child: Icon(iconData,
              color: favorite.isQuickAdd
                  ? colors.primary
                  : colors.onSurface.withOpacity(0.5)),
        ),
        title: Text(favorite.displayName ?? favorite.beverageName),
        subtitle: Text('${vol.toStringAsFixed(1)} oz'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick Add toggle
            Switch(
              value: favorite.isQuickAdd,
              onChanged: (_) => context
                  .read<FavoriteDrinksProvider>()
                  .toggleQuickAdd(favorite.id),
            ),
            // Edit button
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditDialog(context),
              tooltip: 'Edit',
            ),
          ],
        ),
      ),
    );
  }
}
