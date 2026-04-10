import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_card.dart';
import '../../data/dao/beverages_dao.dart';
import '../../data/models/beverage.dart';
import '../../application/providers/hydration_provider.dart';
import '../../application/providers/profile_provider.dart';
import '../../application/providers/favorite_drinks_provider.dart';
import '../../data/models/favorite_drink.dart';

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
      final favProvider = context.read<FavoriteDrinksProvider>();

      await profileProvider.loadProfile();
      hydrationProvider.setAlcoholLimit(profileProvider.dailyAlcoholLimit);

      if (favProvider.favorites.isEmpty) {
        await favProvider.loadFavorites();
      }
    });
  }

  // ==================== QUICK ADD DRINK ====================

  Future<void> _quickAddDrink(FavoriteDrink favorite) async {
    try {
      Beverage? beverage = await dao.getAlcoholicBeverageByExactName(
        favorite.beverageName,
      );

      if (beverage == null) {
        debugPrint('Drink not found: ${favorite.beverageName}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Drink not found: ${favorite.beverageName}'),
            ),
          );
        }
        return;
      }

      final volumeOz =
          (favorite.customVolumeOz ?? beverage.defaultVolumeOz).toDouble();

      if (!mounted) return;
      final provider = context.read<HydrationProvider>();
      await provider.addDrink(beverage, volumeOz: volumeOz);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${volumeOz.toStringAsFixed(1)} oz of ${favorite.beverageName}',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding drink: $e');
    }
  }

  // ==================== OPEN LIBRARY ====================

  Future<void> _openAlcoholDrinkLibrary() async {
    final selectedBeverage = await Navigator.pushNamed(context, '/alclib');

    // Always reload favorites when returning from the library
    if (mounted) {
      await context.read<FavoriteDrinksProvider>().loadFavorites();
    }

    if (selectedBeverage != null && selectedBeverage is Beverage) {
      if (!mounted) return;
      final provider = context.read<HydrationProvider>();
      await provider.addDrink(selectedBeverage);
    }
  }

  // ==================== STANDARD DRINK INFO POPUP ====================

  void _showStandardDrinkInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_bar, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('What is a Standard Drink?'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'A standard drink is a unit used to measure how much pure alcohol you are consuming, regardless of the type of drink.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              // ── What counts as 1 standard drink ──────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1 Standard Drink =',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 8),
                    _InfoRow(emoji: '🍺', text: '12 oz regular beer (5% ABV)'),
                    _InfoRow(emoji: '🍷', text: '5 oz wine (12% ABV)'),
                    _InfoRow(emoji: '🥃', text: '1.5 oz spirit/shot (40% ABV)'),
                    _InfoRow(emoji: '🍹', text: '8–9 oz malt liquor (7% ABV)'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── How we calculate it ───────────────────────────
              const Text(
                'How HydraTrack calculates it:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Standard Drinks =\n(Volume oz × ABV%) ÷ 0.6',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Example: A 12 oz beer at 5% ABV\n= (12 × 0.05) ÷ 0.6 = 1.0 standard drink',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Guidelines ────────────────────────────────────
              const Text(
                'Guidelines:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              const _InfoRow(
                emoji: '✅',
                text: 'Low risk: Up to 2 standard drinks per day',
              ),
              const _InfoRow(
                emoji: '⚠️',
                text: 'Moderate risk: 3–4 standard drinks per day',
              ),
              const _InfoRow(
                emoji: '🚨',
                text: 'Heavy drinking: 5+ standard drinks in one day',
              ),
              const SizedBox(height: 12),
              Text(
                'Guidelines from the National Institute on Alcohol Abuse and Alcoholism (NIAAA).',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HydrationProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final favProvider = context.watch<FavoriteDrinksProvider>();

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
                  // ── Header row with info button ──────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Alcohol',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () => _showStandardDrinkInfo(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.help_outline,
                                  size: 14,
                                  color: Colors.orange.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'What is a standard drink?',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Progress bar ──────────────────────────────
                  LinearProgressIndicator(
                    value: alcoholRatio,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      alcoholRatio >= 0.8 ? Colors.red : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${provider.alcoholCurrent.toStringAsFixed(1)} / '
                    '$alcoholLimit standard drinks today',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==================== QUICK ADD SECTION ====================
            _buildQuickAddSection(favProvider),

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
              break;
            case 4:
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: 'Log'),
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events), label: 'Goals'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_bar), label: 'Alcohol'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  // ==================== QUICK ADD SECTION ====================

  Widget _buildQuickAddSection(FavoriteDrinksProvider favProvider) {
    final quickAdds = favProvider.alcoholQuickAddFavorites;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Add',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Navigator.pushNamed(context, '/alclib');
                  if (mounted) {
                    await context
                        .read<FavoriteDrinksProvider>()
                        .loadFavorites();
                  }
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (quickAdds.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      'No Quick Add drinks set.\nGo to the library, star a drink,\nthen enable Quick Add.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/alclib');
                        if (mounted) {
                          await context
                              .read<FavoriteDrinksProvider>()
                              .loadFavorites();
                        }
                      },
                      icon: const Icon(Icons.local_bar),
                      label: const Text('Browse Library'),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: quickAdds.length + 1,
              itemBuilder: (context, index) {
                if (index == quickAdds.length) {
                  return _buildQuickAddButton(
                    icon: Icons.add,
                    label: 'More',
                    onTap: _openAlcoholDrinkLibrary,
                    isHighlighted: true,
                  );
                }
                return _buildFavoriteButton(quickAdds[index]);
              },
            ),
        ],
      ),
    );
  }

  // ==================== FAVORITE BUTTON ====================

  Widget _buildFavoriteButton(FavoriteDrink favorite) {
    IconData icon = Icons.local_bar;
    if (favorite.customIcon == 'local_drink') icon = Icons.local_drink;
    if (favorite.customIcon == 'water_drop') icon = Icons.water_drop;
    if (favorite.customIcon == 'coffee') icon = Icons.coffee;
    if (favorite.customIcon == 'bolt') icon = Icons.bolt;
    if (favorite.customIcon == 'local_bar') icon = Icons.local_bar;

    final displayName = favorite.beverageName.split(' ').first;
    final volumeOz = favorite.customVolumeOz ?? 12.0;

    return _buildQuickAddButton(
      icon: icon,
      label: displayName,
      subtitle: '${volumeOz.toStringAsFixed(0)} oz',
      onTap: () => _quickAddDrink(favorite),
    );
  }

  // ==================== QUICK ADD BUTTON ====================

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
          color: isHighlighted ? Colors.orange : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isHighlighted ? Colors.orange : Colors.orange.shade200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color:
                  isHighlighted ? Colors.white : Colors.orange.shade700,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isHighlighted
                    ? Colors.white
                    : Colors.orange.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isHighlighted
                      ? Colors.white70
                      : Colors.orange.shade500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==================== HELPER WIDGET ====================

class _InfoRow extends StatelessWidget {
  final String emoji;
  final String text;

  const _InfoRow({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}