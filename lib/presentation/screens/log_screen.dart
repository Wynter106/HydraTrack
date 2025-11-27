import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/providers/hydration_provider.dart';
import '../widgets/app_card.dart';

/// LogScreen - Shows today's drink history
/// 
/// This screen:
/// - Displays all drinks logged today from Provider
/// - Shows same data as HomeScreen (shared via Provider)
/// - Allows deleting drinks from the log
/// - Updates automatically when Provider data changes
class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get data from Provider (same data HomeScreen uses)
    final provider = Provider.of<HydrationProvider>(context);
    final logs = provider.todayLogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Log'),
        backgroundColor: Colors.blue,
        actions: [
          // Show total count
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${logs.length} drinks',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ==================== SUMMARY CARD ====================
          // Shows same totals as HomeScreen (from Provider)
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Hydration total
                Column(
                  children: [
                    const Icon(Icons.water_drop, color: Colors.blue),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.hydrationCurrent.toStringAsFixed(1)} oz',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text('/ ${provider.hydrationGoal.toStringAsFixed(0)} oz goal'),
                  ],
                ),
                // Caffeine total
                Column(
                  children: [
                    Icon(
                      Icons.bolt,
                      color: provider.isNearCaffeineLimit ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.caffeineCurrent.toStringAsFixed(0)} mg',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: provider.isNearCaffeineLimit ? Colors.red : null,
                      ),
                    ),
                    Text('/ ${provider.caffeineLimit.toStringAsFixed(0)} mg limit'),
                  ],
                ),
              ],
            ),
          ),
        ),

          // ==================== DRINK LOG LIST ====================
          // Shows all drinks added from HomeScreen
          Expanded(
            child: logs.isEmpty
                // Empty state
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_drink_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No drinks logged yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add drinks from Home screen',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                // Log list
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      // Show newest first (reverse order)
                      final reversedIndex = logs.length - 1 - index;
                      final log = logs[reversedIndex];
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: AppCard(
                        child: ListTile(
                          // Drink icon
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getIconForDrink(log['beverageName'] as String?),
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(log['timestamp'] as String?),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                          // Drink name
                          title: Text(
                            log['beverageName'] as String? ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          // Drink details
                          subtitle: Text(
                            'Volume: ${(log['volumeOz'] as double?)?.toStringAsFixed(1) ?? '?'} oz\n'
                            'Hydration: +${(log['actualHydrationOz'] as double?)?.toStringAsFixed(1) ?? '?'} oz '
                            '(factor: ${log['hydrationFactor'] ?? '?'})\n'
                            'Caffeine: +${(log['caffeineMg'] as double?)?.toStringAsFixed(0) ?? '0'} mg'
                          ),
                          isThreeLine: true,
                          // Delete button
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _confirmDelete(context, provider, reversedIndex, log),
                          ),
                        ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Shows confirmation dialog before deleting a drink
  void _confirmDelete(
    BuildContext context, 
    HydrationProvider provider, 
    int index, 
    Map<String, dynamic> log
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove drink?'),
        content: Text('Remove ${log['beverageName']} from today\'s log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.removeDrink(index);
              Navigator.pop(context);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns appropriate icon based on drink name
  IconData _getIconForDrink(String? name) {
    if (name == null) return Icons.local_drink;
    final lowerName = name.toLowerCase();
    
    if (lowerName.contains('water')) return Icons.water_drop;
    if (lowerName.contains('coffee')) return Icons.coffee;
    if (lowerName.contains('tea')) return Icons.emoji_food_beverage;
    if (lowerName.contains('energy') || lowerName.contains('red bull')) return Icons.bolt;
    if (lowerName.contains('cola') || lowerName.contains('soda')) return Icons.local_drink;
    
    return Icons.local_drink;
  }

  /// Formats ISO timestamp to readable time (HH:MM)
  String _formatTime(String? timestamp) {
    if (timestamp == null) return '--:--';
    try {
      final dt = DateTime.parse(timestamp);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return '--:--';
    }
  }
}