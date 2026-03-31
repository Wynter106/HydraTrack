import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/providers/hydration_provider.dart';
import '../../application/providers/profile_provider.dart';
import '../widgets/app_card.dart';

/// LogScreen - Shows today's drink history
class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HydrationProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final unit = profileProvider.preferredVolumeUnit;
    final logs = provider.todayLogs;

    double toDisplay(double oz) => unit == 'ml' ? oz * 29.5735 : oz;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Log'),
        backgroundColor: Colors.blue,
        actions: [
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
                        '${toDisplay(provider.hydrationCurrent).toStringAsFixed(1)} $unit',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text('/ ${toDisplay(provider.hydrationGoal).toStringAsFixed(0)} $unit goal'),
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

          // ==================== STATS BUTTONS (NEW) ====================
          // 통계 화면으로 이동하는 버튼 추가
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/weekly-stats');
                    },
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('Weekly'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/monthly-stats');
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Monthly'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8), // 약간의 여백

          // ==================== DRINK LOG LIST ====================
          Expanded(
            child: logs.isEmpty
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
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = logs.length - 1 - index;
                      final log = logs[reversedIndex];
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: AppCard(
                          child: ListTile(
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getIconForDrink(log['beverageName'] as String?, log['caffeineMg'] as double?),
                                  color: _getColorForDrink(log['beverageName'] as String?, log['caffeineMg'] as double?),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(log['timestamp'] as String?),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                            title: Text(
                              log['beverageName'] as String? ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Volume: ${toDisplay((log['volumeOz'] as double?) ?? 0).toStringAsFixed(1)} $unit\n'
                              'Hydration: +${toDisplay((log['actualHydrationOz'] as double?) ?? 0).toStringAsFixed(1)} $unit '
                              '(factor: ${log['hydrationFactor'] ?? '?'})\n'
                              'Caffeine: +${(log['caffeineMg'] as double?)?.toStringAsFixed(0) ?? '0'} mg'
                            ),
                            isThreeLine: true,
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

  IconData _getIconForDrink(String? name, double? caff) {
    if (name == null || caff == null) return Icons.local_drink;
    final lowerName = name.toLowerCase();
    
    if (lowerName.contains('water')) return Icons.water_drop;
    if (lowerName.contains('coffee') || lowerName.contains('mocha') || lowerName.contains('latte') || lowerName.contains('cold brew') || lowerName.contains('cappuccino')) return Icons.coffee;
    if (lowerName.contains('tea') || lowerName.contains('chai')) return Icons.emoji_food_beverage;
    if (lowerName.contains('energy') || lowerName.contains('red bull') || caff > 70) return Icons.bolt;
    if (lowerName.contains('cola') || lowerName.contains('soda')) return Icons.local_drink;
    
    return Icons.local_drink;
  }

  Color _getColorForDrink(String? name, double? caff) {
    if (name == null || caff == null) return Colors.grey;
    final lowerName = name.toLowerCase();
    
    if (lowerName.contains('water')) return Colors.blue;
    if (lowerName.contains('coffee') || lowerName.contains('mocha') || lowerName.contains('latte') || lowerName.contains('cold brew') || lowerName.contains('cappuccino')) return Colors.black;
    if (lowerName.contains('tea') || lowerName.contains('chai')) return Colors.green;
    if (lowerName.contains('energy') || lowerName.contains('red bull') || caff > 70) return Colors.orange;
    if (lowerName.contains('cola') || lowerName.contains('soda')) return Colors.red;
    
    return Colors.grey;
  }

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