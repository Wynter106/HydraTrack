import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/beverage.dart';
import '../../data/models/drink_log.dart';
import '../../business/calculators/hydration_calculator.dart';
import '../../business/calculators/caffeine_tracker.dart';

class HydrationProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  double _hydrationCurrent = 0;
  double get hydrationCurrent => _hydrationCurrent;
  
  double _caffeineCurrent = 0;
  double get caffeineCurrent => _caffeineCurrent;
  
  double _hydrationGoal = 64;
  double get hydrationGoal => _hydrationGoal;
  
  double _caffeineLimit = 400;
  double get caffeineLimit => _caffeineLimit;

  int _currentStreak = 0;
  int get currentStreak => _currentStreak;

  int _longestStreak = 0;
  int get longestStreak => _longestStreak;

  double _lifetimeOunces = 0;
  double get lifetimeOunces => _lifetimeOunces;

  int _lifetimeDrinkCount = 0;
  int get lifetimeDrinkCount => _lifetimeDrinkCount;

  bool get hasEarlyLog {
    for (final log in _todayLogs) {
      final timestamp = DateTime.parse(log['timestamp'] as String);
      if (timestamp.hour < 8) return true;
    }
    return false;
  }

  bool get hasLateLog {
    for (final log in _todayLogs) {
      final timestamp = DateTime.parse(log['timestamp'] as String);
      if (timestamp.hour >= 21) return true;
    }
    return false;
  }

  int get uniqueDrinkTypesToday {
    final uniqueNames = <String>{};
    for (final log in _todayLogs) {
      uniqueNames.add(log['beverageName'] as String);
    }
    return uniqueNames.length;
  }
  
  final List<Map<String, dynamic>> _todayLogs = [];
  List<Map<String, dynamic>> get todayLogs => List.unmodifiable(_todayLogs);
  int get logCount => _todayLogs.length;

  final List<Map<String, dynamic>> _allLogs = [];
  List<Map<String, dynamic>> get allLogs => List.unmodifiable(_allLogs);
  
  double get hydrationProgress => 
      HydrationCalculator.calculateProgress(_hydrationCurrent, _hydrationGoal);
  
  double get caffeineProgress => 
      CaffeineTracker.calculateProgress(_caffeineCurrent, dailyLimit: _caffeineLimit);
  
  bool get isNearCaffeineLimit => 
      CaffeineTracker.isNearLimit(_caffeineCurrent, dailyLimit: _caffeineLimit);
  
  bool get isOverCaffeineLimit => 
      CaffeineTracker.isOverLimit(_caffeineCurrent, dailyLimit: _caffeineLimit);
  
  double get hydrationRemaining => 
      HydrationCalculator.calculateRemaining(_hydrationCurrent, _hydrationGoal);
  
  double get caffeineRemaining => 
      CaffeineTracker.calculateRemaining(_caffeineCurrent, dailyLimit: _caffeineLimit);
  
  Future<void> loadTodayLogs() async {
    final userId = _supabase.auth.currentUser?.id;
    
    debugPrint('═══════════════════════════════');
    debugPrint('🔍 loadTodayLogs() START');
    debugPrint('🔍 User ID: $userId');
    
    if (userId == null) {
      debugPrint('❌ User ID is NULL - not logged in!');
      debugPrint('═══════════════════════════════');
      return;
    }
    
    try {
      final now = DateTime.now().toUtc();
      final startOfDay = DateTime.utc(now.year, now.month, now.day);
      
      debugPrint('🔍 Current UTC time: $now');
      debugPrint('🔍 Start of day UTC: $startOfDay');
      debugPrint('🔍 Querying Supabase...');
      
      final data = await _supabase
          .from('beverage_logs')
          .select()
          .eq('user_id', userId)
          .gte('logged_at', startOfDay.toIso8601String())
          .order('logged_at', ascending: false);
      
      debugPrint('🔍 Supabase response length: ${data.length}');
      debugPrint('🔍 Raw data: $data');
      
      _hydrationCurrent = 0;
      _caffeineCurrent = 0;
      _todayLogs.clear();
      
      for (int i = 0; i < data.length; i++) {
        final json = data[i];
        debugPrint('  [$i] ${json['beverage_name']} | ${json['amount_oz']}oz | ${json['logged_at']}');
        
        final hydration = (json['hydration_contribution_oz'] as num?)?.toDouble() ?? 0;
        final caffeine = (json['caffeine_mg'] as num?)?.toDouble() ?? 0;
        final volume = (json['amount_oz'] as num?)?.toDouble() ?? 0;
        
        _hydrationCurrent += hydration;
        _caffeineCurrent += caffeine;
        
        final logEntry = {
          'beverageId': 0,
          'beverageName': json['beverage_name'] ?? '',
          'volumeOz': volume,
          'actualHydrationOz': hydration,
          'caffeineMg': caffeine,
          'hydrationFactor': volume > 0 ? hydration / volume : 0,
          'timestamp': json['logged_at'],
        };
        
        _todayLogs.add(logEntry);
        _allLogs.add(logEntry);
      }
      
      debugPrint('✅ Loaded ${_todayLogs.length} logs');
      debugPrint('✅ Total hydration: ${_hydrationCurrent.toStringAsFixed(1)} oz');
      debugPrint('✅ Total caffeine: ${_caffeineCurrent.toStringAsFixed(0)} mg');
      debugPrint('═══════════════════════════════');
      
      notifyListeners();
      
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════');
    }
  }
  
  Future<Map<String, double>> addDrink(Beverage beverage, {double? volumeOz}) async {
    final volume = volumeOz ?? beverage.defaultVolumeOz.toDouble();
    
    final actualHydration = HydrationCalculator.calculateFromBeverage(
      beverage, 
      volumeOz: volume,
    );
    final caffeine = CaffeineTracker.calculateFromBeverage(
      beverage, 
      volumeOz: volume,
    );
    
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _supabase.from('beverage_logs').insert({
          'user_id': userId,
          'beverage_name': beverage.name,
          'amount_oz': volume,
          'caffeine_mg': caffeine.round(),
          'hydration_contribution_oz': actualHydration,
          'logged_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Error saving to Supabase: $e');
      }
    }
    
    final logEntry = {
      'beverageId': beverage.id ?? 0,
      'beverageName': beverage.name,
      'volumeOz': volume,
      'actualHydrationOz': actualHydration,
      'caffeineMg': caffeine,
      'hydrationFactor': beverage.hydrationFactor,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _hydrationCurrent += actualHydration;
    _caffeineCurrent += caffeine;
    _lifetimeOunces += actualHydration;
    _lifetimeDrinkCount++;
    
    _todayLogs.add(logEntry);
    _allLogs.add(logEntry);

    notifyListeners();
    
    return {
      'hydration': actualHydration,
      'caffeine': caffeine,
    };
  }
  
  void removeDrink(int index) {
    if (index < 0 || index >= _todayLogs.length) return;
    
    final log = _todayLogs[index];
    
    _hydrationCurrent -= (log['actualHydrationOz'] as double?) ?? 0;
    _caffeineCurrent -= (log['caffeineMg'] as double?) ?? 0;
    
    if (_hydrationCurrent < 0) _hydrationCurrent = 0;
    if (_caffeineCurrent < 0) _caffeineCurrent = 0;
    
    final ts = log['timestamp'] as String?;
    if (ts != null) {
      _allLogs.removeWhere((x) => x['timestamp'] == ts);
    }

    _todayLogs.removeAt(index);
    
    notifyListeners();
  }
  
  void resetDay() {
    if (_hydrationCurrent >= _hydrationGoal) {
      _currentStreak++;
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
      }
    } else {
      _currentStreak = 0;
    }
    
    _hydrationCurrent = 0;
    _caffeineCurrent = 0;
    _todayLogs.clear();
    notifyListeners();
  }
  
  void setHydrationGoal(double goal) {
    if (goal > 0) {
      _hydrationGoal = goal;
      notifyListeners();
    }
  }
  
  void setCaffeineLimit(double limit) {
    if (limit > 0) {
      _caffeineLimit = limit;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getLogsBetween(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

    return _allLogs.where((log) {
      final ts = log['timestamp'] as String?;
      final dt = ts == null ? null : DateTime.tryParse(ts);
      if (dt == null) return false;
      return !dt.isBefore(s) && !dt.isAfter(e);
    }).toList();
  }
}