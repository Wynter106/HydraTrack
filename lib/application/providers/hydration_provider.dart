import 'package:flutter/material.dart';
import '../../data/models/beverage.dart';
import '../../data/models/drink_log.dart';
import '../../business/calculators/hydration_calculator.dart';
import '../../business/calculators/caffeine_tracker.dart';

/// HydrationProvider - Central state management for hydration tracking
/// 
/// This provider:
/// - Stores today's hydration and caffeine totals
/// - Keeps a list of all drinks logged today
/// - Uses HydrationCalculator and CaffeineTracker for calculations
/// - Notifies all screens when data changes
/// 
/// How Provider works:
/// 1. User adds a drink in HomeScreen
/// 2. Provider calculates and stores the data
/// 3. Provider calls notifyListeners()
/// 4. All screens watching this provider rebuild automatically
/// 5. LogScreen shows the new drink without any extra code
class HydrationProvider extends ChangeNotifier {
  
  // ==================== CURRENT TOTALS ====================
  
  /// Today's total hydration in oz
  double _hydrationCurrent = 0;
  double get hydrationCurrent => _hydrationCurrent;
  
  /// Today's total caffeine in mg
  double _caffeineCurrent = 0;
  double get caffeineCurrent => _caffeineCurrent;
  
  // ==================== DAILY GOALS ====================
  
  /// Daily hydration goal in oz (default: 64oz = ~2 liters)
  /// TODO: Load from UserSettings database
  double _hydrationGoal = 64;
  double get hydrationGoal => _hydrationGoal;
  
  /// Daily caffeine limit in mg (FDA recommendation: 400mg)
  /// TODO: Load from UserSettings database
  double _caffeineLimit = 400;
  double get caffeineLimit => _caffeineLimit;

  // ==================== STREAK TRACKING ====================

/// Current consecutive days meeting hydration goal
int _currentStreak = 0;
int get currentStreak => _currentStreak;

/// Longest streak ever achieved
int _longestStreak = 0;
int get longestStreak => _longestStreak;

// ==================== LIFETIME STATS ====================

/// Total ounces logged across all time
double _lifetimeOunces = 0;
double get lifetimeOunces => _lifetimeOunces;

/// Total number of drinks logged all time
int _lifetimeDrinkCount = 0;
int get lifetimeDrinkCount => _lifetimeDrinkCount;

// ==================== TIME-BASED GOAL GETTERS ====================

/// True if user logged a drink before 8 AM today
bool get hasEarlyLog {
  for (final log in _todayLogs) {
    final timestamp = DateTime.parse(log['timestamp'] as String);
    if (timestamp.hour < 8) return true;
  }
  return false;
}

/// True if user logged a drink after 9 PM today
bool get hasLateLog {
  for (final log in _todayLogs) {
    final timestamp = DateTime.parse(log['timestamp'] as String);
    if (timestamp.hour >= 21) return true;
  }
  return false;
}

// ==================== VARIETY TRACKING ====================

/// Number of unique drink types logged today
int get uniqueDrinkTypesToday {
  final uniqueNames = <String>{};
  for (final log in _todayLogs) {
    uniqueNames.add(log['beverageName'] as String);
  }
  return uniqueNames.length;
}
  
  // ==================== DRINK LOGS ====================
  
  /// List of all drinks logged today
  /// Each entry contains: beverageId, volume, timestamp, actualHydration
  final List<Map<String, dynamic>> _todayLogs = [];
  
  /// Returns a copy of today's logs (prevents external modification)
  List<Map<String, dynamic>> get todayLogs => List.unmodifiable(_todayLogs);
  
  /// Number of drinks logged today
  int get logCount => _todayLogs.length;


  /// List of all drinks logged (for weekly/monthly stats)
  final List<Map<String, dynamic>> _allLogs = [];

  /// Returns a copy of all logs
  List<Map<String, dynamic>> get allLogs => List.unmodifiable(_allLogs);
  

  // ==================== PROGRESS GETTERS ====================
  
  /// Hydration progress as percentage (0.0 to 1.0)
  double get hydrationProgress => 
      HydrationCalculator.calculateProgress(_hydrationCurrent, _hydrationGoal);
  
  /// Caffeine progress as percentage (0.0 to 1.0)
  double get caffeineProgress => 
      CaffeineTracker.calculateProgress(_caffeineCurrent, dailyLimit: _caffeineLimit);
  
  /// True if caffeine is at 80% or more of daily limit
  bool get isNearCaffeineLimit => 
      CaffeineTracker.isNearLimit(_caffeineCurrent, dailyLimit: _caffeineLimit);
  
  /// True if caffeine has exceeded daily limit
  bool get isOverCaffeineLimit => 
      CaffeineTracker.isOverLimit(_caffeineCurrent, dailyLimit: _caffeineLimit);
  
  /// Remaining hydration needed to reach goal (oz)
  double get hydrationRemaining => 
      HydrationCalculator.calculateRemaining(_hydrationCurrent, _hydrationGoal);
  
  /// Remaining caffeine allowed today (mg)
  double get caffeineRemaining => 
      CaffeineTracker.calculateRemaining(_caffeineCurrent, dailyLimit: _caffeineLimit);
  
  // ==================== METHODS ====================
  
  /// Adds a drink to today's log
  /// 
  /// Parameters:
  /// - beverage: The beverage object from database
  /// - volumeOz: Amount consumed (optional, uses beverage default if not provided)
  /// 
  /// This method:
  /// 1. Calculates actual hydration using HydrationCalculator
  /// 2. Calculates caffeine using CaffeineTracker
  /// 3. Creates a log entry with all details
  /// 4. Updates totals
  /// 5. Notifies all screens to rebuild
  /// 
  /// Returns: Map containing the calculated values for display
  Map<String, double> addDrink(Beverage beverage, {double? volumeOz}) {
    // Use provided volume or beverage's default
    final volume = volumeOz ?? beverage.defaultVolumeOz.toDouble();
    
    // Calculate using Business Layer
    final actualHydration = HydrationCalculator.calculateFromBeverage(
      beverage, 
      volumeOz: volume,
    );
    final caffeine = CaffeineTracker.calculateFromBeverage(
      beverage, 
      volumeOz: volume,
    );
    
    // Create log entry
    final logEntry = {
      'beverageId': beverage.id ?? 0,
      'beverageName': beverage.name,
      'volumeOz': volume,
      'actualHydrationOz': actualHydration,
      'caffeineMg': caffeine,
      'hydrationFactor': beverage.hydrationFactor,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Update totals
    _hydrationCurrent += actualHydration;
    _caffeineCurrent += caffeine;
    // Update lifetime stats
    _lifetimeOunces += actualHydration;
    _lifetimeDrinkCount++;
    
    // Add to log list
    _todayLogs.add(logEntry);
    
    // Add to all logs (for weekly/monthly stats)
    _allLogs.add(logEntry);

    // Notify all screens to rebuild with new data
    notifyListeners();
    
    // Return calculated values for SnackBar display
    return {
      'hydration': actualHydration,
      'caffeine': caffeine,
    };
  }
  
  /// Removes a drink from today's log by index
  /// 
  /// Parameters:
  /// - index: Position in the log list (0-based)
  /// 
  /// This also subtracts the drink's values from today's totals
  void removeDrink(int index) {
    // Validate index
    if (index < 0 || index >= _todayLogs.length) return;
    
    // Get the log entry
    final log = _todayLogs[index];
    
    // Subtract from totals
    _hydrationCurrent -= (log['actualHydrationOz'] as double?) ?? 0;
    _caffeineCurrent -= (log['caffeineMg'] as double?) ?? 0;
    
    // Prevent negative values
    if (_hydrationCurrent < 0) _hydrationCurrent = 0;
    if (_caffeineCurrent < 0) _caffeineCurrent = 0;
    
    // Also remove allLogs
    final ts = log['timestamp'] as String?;
    if (ts != null) {
      _allLogs.removeWhere((x) => x['timestamp'] == ts);
    }

    // Remove from list
    _todayLogs.removeAt(index);
    
    // Notify all screens
    notifyListeners();
  }
  
  /// Resets all data for a new day
  /// 
  /// Call this:
  /// - When app detects a new day
  /// - When user manually resets
  /// - For testing purposes
  void resetDay() {
    // Check if yesterday met the goal before resetting
  if (_hydrationCurrent >= _hydrationGoal) {
    _currentStreak++;
    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }
  } else {
    _currentStreak = 0; // Streak broken
  }
  
  _hydrationCurrent = 0;
  _caffeineCurrent = 0;
  _todayLogs.clear();
  notifyListeners();
  }
  
  /// Updates the daily hydration goal
  /// 
  /// Parameters:
  /// - goal: New goal in oz
  /// 
  /// Call this when user changes goal in Settings
  void setHydrationGoal(double goal) {
    if (goal > 0) {
      _hydrationGoal = goal;
      notifyListeners();
    }
  }
  
  /// Updates the daily caffeine limit
  /// 
  /// Parameters:
  /// - limit: New limit in mg
  /// 
  /// Call this when user changes limit in Settings
  void setCaffeineLimit(double limit) {
    if (limit > 0) {
      _caffeineLimit = limit;
      notifyListeners();
    }
  }

  /// Returns logs between start and end dates (inclusive)
  /// Used for weekly/monthly stats
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