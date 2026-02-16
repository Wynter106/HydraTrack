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
    if (userId == null) return;
    
    try {
      final now = DateTime.now().toUtc();
      final startOfDay = DateTime.utc(now.year, now.month, now.day);
      
      final data = await _supabase
          .from('beverage_logs')
          .select()
          .eq('user_id', userId)
          .gte('logged_at', startOfDay.toIso8601String())
          .order('logged_at', ascending: false);
      
      _hydrationCurrent = 0;
      _caffeineCurrent = 0;
      _todayLogs.clear();
      
      for (final json in data) {
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
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error loading logs: $e');
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

  // ===== TIME-BASED CHECKS =====

// Very early log (before 6 AM)
bool get hasVeryEarlyLog {
  for (final log in _todayLogs) {
    final ts = log['timestamp'] as String?;
    if (ts == null) continue;
    final dt = DateTime.tryParse(ts);
    if (dt != null && dt.hour < 6) return true;
  }
  return false;
}

// Lunch log (11 AM - 1 PM)
bool get hasLunchLog {
  for (final log in _todayLogs) {
    final ts = log['timestamp'] as String?;
    if (ts == null) continue;
    final dt = DateTime.tryParse(ts);
    if (dt != null && dt.hour >= 11 && dt.hour < 13) return true;
  }
  return false;
}

// Afternoon log (2 PM - 4 PM)
bool get hasAfternoonLog {
  for (final log in _todayLogs) {
    final ts = log['timestamp'] as String?;
    if (ts == null) continue;
    final dt = DateTime.tryParse(ts);
    if (dt != null && dt.hour >= 14 && dt.hour < 16) return true;
  }
  return false;
}


// ===== WEEKEND TRACKING =====

// For now, this checks if TODAY is a weekend day and goal is met
// For full weekend tracking, you'd need to persist data across days
int get weekendDaysCompleted {
  final now = DateTime.now();
  final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
  
  if (isWeekend && _hydrationCurrent >= _hydrationGoal) {
    return 1; // Today counts
  }
  return 0;
  
  // TODO: For full implementation, you'd query Supabase for 
  // Saturday and Sunday of the current week
}

bool get weekendGoalsMet => weekendDaysCompleted >= 2;


// ===== VARIETY CHECKS =====

// Check if all drinks today are water
bool get isWaterOnlyDay {
  if (_todayLogs.isEmpty) return true; // No drinks = technically water only
  
  for (final log in _todayLogs) {
    final name = (log['beverageName'] as String?)?.toLowerCase() ?? '';
    if (!name.contains('water')) return false;
  }
  return true;
}


// ===== RAPID LOGGING CHECK =====

// 3 drinks within 1 hour
bool get hasRapidLogs {
  if (_todayLogs.length < 3) return false;
  
  // Parse all timestamps and sort
  final timestamps = <DateTime>[];
  for (final log in _todayLogs) {
    final ts = log['timestamp'] as String?;
    if (ts == null) continue;
    final dt = DateTime.tryParse(ts);
    if (dt != null) timestamps.add(dt);
  }
  
  if (timestamps.length < 3) return false;
  timestamps.sort((a, b) => a.compareTo(b));
  
  // Check for any 3 consecutive logs within 60 minutes
  for (int i = 0; i <= timestamps.length - 3; i++) {
    final diff = timestamps[i + 2].difference(timestamps[i]);
    if (diff.inMinutes <= 60) return true;
  }
  return false;
}


// ===== STEADY HYDRATION =====

// Checks if user logged at least 1 drink in each 2-hour slot from 8 AM - 8 PM
int get hourlySlotsFilled {
  final slots = [8, 10, 12, 14, 16, 18]; // Start hours for each slot
  int filled = 0;
  
  for (final slotStart in slots) {
    bool hasLogInSlot = false;
    
    for (final log in _todayLogs) {
      final ts = log['timestamp'] as String?;
      if (ts == null) continue;
      final dt = DateTime.tryParse(ts);
      if (dt != null && dt.hour >= slotStart && dt.hour < slotStart + 2) {
        hasLogInSlot = true;
        break;
      }
    }
    
    if (hasLogInSlot) filled++;
  }
  
  return filled;
}

bool get hasSteadyHydration => hourlySlotsFilled >= 6;


// ===== SIZE-BASED CHECKS =====

// Check if any single drink is 32+ oz
bool get hasLargeDrink {
  for (final log in _todayLogs) {
    final volume = (log['volumeOz'] as num?)?.toDouble() ?? 0;
    if (volume >= 32) return true;
  }
  return false;
}

// Count drinks under 8 oz
int get smallDrinkCount {
  int count = 0;
  for (final log in _todayLogs) {
    final volume = (log['volumeOz'] as num?)?.toDouble() ?? 0;
    if (volume > 0 && volume < 8) count++;
  }
  return count;
}
}