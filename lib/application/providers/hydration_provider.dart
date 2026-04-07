import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/beverage.dart';
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

  double _alcoholCurrent = 0;
  double get alcoholCurrent => _alcoholCurrent;

  double _alcoholLimit = 2.0;
  double get alcoholLimit => _alcoholLimit;

  int _lifetimeDrinkCount = 0;
  int get lifetimeDrinkCount => _lifetimeDrinkCount;

  double _lifetimeStandardDrinks = 0;
  double get lifetimeStandardDrinks => _lifetimeStandardDrinks;

  final List<Map<String, dynamic>> _todayLogs = [];
  List<Map<String, dynamic>> get todayLogs => List.unmodifiable(_todayLogs);
  int get logCount => _todayLogs.length;

  final List<Map<String, dynamic>> _allLogs = [];
  List<Map<String, dynamic>> get allLogs => List.unmodifiable(_allLogs);

  // ===== COMPUTED PROPERTIES =====

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

  // ===== DATABASE OPERATIONS =====

  /// Load today's logs from Supabase
  Future<void> loadTodayLogs() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Use local time for date boundary so "today" means today in user's timezone
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toUtc();

      final data = await _supabase
          .from('beverage_logs')
          .select()
          .eq('user_id', userId)
          .gte('logged_at', startOfDay.toIso8601String())
          .lte('logged_at', endOfDay.toIso8601String())
          .order('logged_at', ascending: false);

      _hydrationCurrent = 0;
      _caffeineCurrent = 0;
      _alcoholCurrent = 0;
      _todayLogs.clear();
      _allLogs.clear();

      for (final json in data) {
        final hydration = (json['hydration_contribution_oz'] as num?)?.toDouble() ?? 0;
        final caffeine = (json['caffeine_mg'] as num?)?.toDouble() ?? 0;
        final volume = (json['amount_oz'] as num?)?.toDouble() ?? 0;
        final isAlcoholic = json['is_alcoholic'] as bool? ?? false;
        final standardDrinks = (json['standard_drinks'] as num?)?.toDouble() ?? 0;

        _hydrationCurrent += hydration;
        _caffeineCurrent += caffeine;
        if (isAlcoholic) _alcoholCurrent += standardDrinks;

        final logEntry = {
          'id': json['id'],
          'beverageId': 0,
          'beverageName': json['beverage_name'] ?? '',
          'volumeOz': volume,
          'actualHydrationOz': hydration,
          'caffeineMg': caffeine,
          'hydrationFactor': volume > 0 ? hydration / volume : 0,
          'isAlcoholic': isAlcoholic,
          'standardDrinks': standardDrinks,
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

  /// Add a drink
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

    final isAlcoholic = beverage.isAlcoholic;
    final abv = beverage.abv ?? 0.0;
    final standardDrinks = isAlcoholic ? (volume * (abv / 100)) / 0.6 : 0.0;

    final userId = _supabase.auth.currentUser?.id;
    String? supabaseId;

    if (userId != null) {
      try {
        final response = await _supabase
            .from('beverage_logs')
            .insert({
              'user_id': userId,
              'beverage_name': beverage.name,
              'amount_oz': volume,
              'caffeine_mg': caffeine.round(),
              'hydration_contribution_oz': actualHydration,
              'is_alcoholic': isAlcoholic,
              'abv': isAlcoholic ? abv : null,
              'standard_drinks': isAlcoholic ? standardDrinks : null,
              'alcohol_source': isAlcoholic ? 'library' : null,
              'logged_at': DateTime.now().toUtc().toIso8601String(),
            })
            .select()
            .single();

        supabaseId = response['id'] as String?;
      } catch (e) {
        debugPrint('Offline — saving drink to local queue: $e');
        await _saveToLocalQueue({
          'beverage_name': beverage.name,
          'amount_oz': volume,
          'caffeine_mg': caffeine.round(),
          'hydration_contribution_oz': actualHydration,
          'is_alcoholic': isAlcoholic,
          'abv': isAlcoholic ? abv : null,
          'standard_drinks': isAlcoholic ? standardDrinks : null,
          'logged_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    }

    final logEntry = {
      'id': supabaseId,
      'beverageId': beverage.id ?? 0,
      'beverageName': beverage.name,
      'volumeOz': volume,
      'actualHydrationOz': actualHydration,
      'caffeineMg': caffeine,
      'hydrationFactor': beverage.hydrationFactor,
      'isAlcoholic': isAlcoholic,
      'standardDrinks': standardDrinks,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _hydrationCurrent += actualHydration;
    _caffeineCurrent += caffeine;
    if (isAlcoholic) {
      _alcoholCurrent += standardDrinks;
      _lifetimeStandardDrinks += standardDrinks;
    }
    _lifetimeOunces += actualHydration;
    _lifetimeDrinkCount++;

    _todayLogs.insert(0, logEntry);
    _allLogs.insert(0, logEntry);

    notifyListeners();

    return {
      'hydration': actualHydration,
      'caffeine': caffeine,
      'standardDrinks': standardDrinks,
    };
  }

  /// Remove a drink
  Future<void> removeDrink(int index) async {
    if (index < 0 || index >= _todayLogs.length) return;

    final log = _todayLogs[index];
    final logId = log['id'] as String?;

    if (logId != null) {
      try {
        await _supabase
            .from('beverage_logs')
            .delete()
            .eq('id', logId);
      } catch (e) {
        debugPrint('Error deleting from Supabase: $e');
        return;
      }
    }

    _hydrationCurrent -= (log['actualHydrationOz'] as double?) ?? 0;
    _caffeineCurrent -= (log['caffeineMg'] as double?) ?? 0;
    final isAlcoholic = log['isAlcoholic'] as bool? ?? false;
    if (isAlcoholic) {
      _alcoholCurrent -= (log['standardDrinks'] as double?) ?? 0;
    }

    if (_hydrationCurrent < 0) _hydrationCurrent = 0;
    if (_caffeineCurrent < 0) _caffeineCurrent = 0;
    if (_alcoholCurrent < 0) _alcoholCurrent = 0;

    final ts = log['timestamp'] as String?;
    if (ts != null) {
      _allLogs.removeWhere((x) => x['timestamp'] == ts);
    }

    _todayLogs.removeAt(index);

    notifyListeners();
  }

  // ===== STATE MANAGEMENT =====

  void clearData() {
    _hydrationCurrent = 0;
    _caffeineCurrent = 0;
    _alcoholCurrent = 0;
    _todayLogs.clear();
    _allLogs.clear();
    _currentStreak = 0;
    _lifetimeOunces = 0;
    _lifetimeStandardDrinks = 0;
    _lifetimeDrinkCount = 0;
    notifyListeners();
  }

  Future<void> resetDay() async {
    if (_hydrationCurrent >= _hydrationGoal) {
      _currentStreak++;
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
      }
    } else {
      _currentStreak = 0;
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
        final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toUtc();

        await _supabase
            .from('beverage_logs')
            .delete()
            .eq('user_id', userId)
            .gte('logged_at', startOfDay.toIso8601String())
            .lte('logged_at', endOfDay.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error deleting today logs from Supabase: $e');
    }

    _hydrationCurrent = 0;
    _caffeineCurrent = 0;
    _alcoholCurrent = 0;
    _todayLogs.clear();
    _allLogs.clear();
    notifyListeners();
  }

  // ===== OFFLINE QUEUE =====

  static const _kPendingLogsKey = 'pending_logs';

  Future<void> _saveToLocalQueue(Map<String, dynamic> log) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_kPendingLogsKey) ?? [];
    existing.add(jsonEncode(log));
    await prefs.setStringList(_kPendingLogsKey, existing);
    debugPrint('📦 Saved to local queue (${existing.length} pending)');
  }

  Future<void> syncPendingLogs() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_kPendingLogsKey) ?? [];
    if (pending.isEmpty) return;

    debugPrint('🔄 Syncing ${pending.length} pending logs...');
    final synced = <String>[];

    for (final jsonStr in pending) {
      try {
        final log = Map<String, dynamic>.from(jsonDecode(jsonStr) as Map);
        await _supabase.from('beverage_logs').insert({...log, 'user_id': userId});
        synced.add(jsonStr);
      } catch (e) {
        debugPrint('Sync failed, will retry later: $e');
        break;
      }
    }

    final remaining = pending.where((s) => !synced.contains(s)).toList();
    await prefs.setStringList(_kPendingLogsKey, remaining);
    debugPrint('✅ Synced ${synced.length} logs, ${remaining.length} remaining');

    if (synced.isNotEmpty) notifyListeners();
  }

  int get pendingLogCount => 0;

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

  void setAlcoholLimit(double limit) {
    if (limit > 0) {
      _alcoholLimit = limit;
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

  bool get hasVeryEarlyLog {
    for (final log in _todayLogs) {
      final ts = log['timestamp'] as String?;
      if (ts == null) continue;
      final dt = DateTime.tryParse(ts);
      if (dt != null && dt.hour < 6) return true;
    }
    return false;
  }

  bool get hasEarlyLog {
    for (final log in _todayLogs) {
      final ts = log['timestamp'] as String?;
      if (ts == null) continue;
      final dt = DateTime.tryParse(ts);
      if (dt != null && dt.hour < 8) return true;
    }
    return false;
  }

  bool get hasLunchLog {
    for (final log in _todayLogs) {
      final ts = log['timestamp'] as String?;
      if (ts == null) continue;
      final dt = DateTime.tryParse(ts);
      if (dt != null && dt.hour >= 11 && dt.hour < 13) return true;
    }
    return false;
  }

  bool get hasAfternoonLog {
    for (final log in _todayLogs) {
      final ts = log['timestamp'] as String?;
      if (ts == null) continue;
      final dt = DateTime.tryParse(ts);
      if (dt != null && dt.hour >= 14 && dt.hour < 16) return true;
    }
    return false;
  }

  bool get hasLateLog {
    for (final log in _todayLogs) {
      final ts = log['timestamp'] as String?;
      if (ts == null) continue;
      final dt = DateTime.tryParse(ts);
      if (dt != null && dt.hour >= 21) return true;
    }
    return false;
  }

  // ===== ALCOHOL STATS & ACHIEVEMENTS =====

  bool get hasHappyHourDrink {
    for (final log in _todayLogs) {
      final isAlcoholic = log['isAlcoholic'] as bool? ?? false;
      if (!isAlcoholic) continue;
      final ts = log['timestamp'] as String?;
      if (ts == null) continue;
      final dt = DateTime.tryParse(ts);
      if (dt != null && dt.hour >= 16 && dt.hour < 19) return true;
    }
    return false;
  }

  int get alcoholDrinkCountToday {
    return _todayLogs
        .where((log) => log['isAlcoholic'] as bool? ?? false)
        .length;
  }

  bool get stayedUnderAlcoholLimit {
    return _alcoholCurrent <= _alcoholLimit && alcoholDrinkCountToday > 0;
  }

  bool get alcoholFreeDay {
    return alcoholDrinkCountToday == 0 && _todayLogs.isNotEmpty;
  }

  bool get responsibleDrinker {
    return _alcoholCurrent > 0 && _alcoholCurrent <= 1.0;
  }

  bool get hydratedAndHappy {
    return alcoholDrinkCountToday > 0 && hydrationProgress >= 1.0;
  }

  int get uniqueAlcoholicDrinksToday {
    final names = _todayLogs
        .where((log) => log['isAlcoholic'] as bool? ?? false)
        .map((log) => log['beverageName'] as String)
        .toSet();
    return names.length;
  }

  bool get alcoholExplorer {
    return uniqueAlcoholicDrinksToday >= 3;
  }

  bool get overAlcoholLimit {
    return _alcoholCurrent > _alcoholLimit;
  }

  // ===== STATISTICS & ACHIEVEMENTS =====

  int get uniqueDrinkTypesToday {
    final uniqueNames = <String>{};
    for (final log in _todayLogs) {
      uniqueNames.add(log['beverageName'] as String);
    }
    return uniqueNames.length;
  }

  int get weekendDaysCompleted {
    final now = DateTime.now();
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    if (isWeekend && _hydrationCurrent >= _hydrationGoal) return 1;
    return 0;
  }

  bool get weekendGoalsMet => weekendDaysCompleted >= 2;

  bool get isWaterOnlyDay {
    if (_todayLogs.isEmpty) return true;
    for (final log in _todayLogs) {
      final name = (log['beverageName'] as String?)?.toLowerCase() ?? '';
      if (!name.contains('water')) return false;
    }
    return true;
  }

  bool get hasRapidLogs {
    if (_todayLogs.length < 3) return false;

    final timestamps = <DateTime>[];
    for (final log in _todayLogs) {
      final ts = log['timestamp'] as String?;
      if (ts == null) continue;
      final dt = DateTime.tryParse(ts);
      if (dt != null) timestamps.add(dt);
    }

    if (timestamps.length < 3) return false;
    timestamps.sort((a, b) => a.compareTo(b));

    for (int i = 0; i <= timestamps.length - 3; i++) {
      final diff = timestamps[i + 2].difference(timestamps[i]);
      if (diff.inMinutes <= 60) return true;
    }
    return false;
  }

  int get hourlySlotsFilled {
    final slots = [8, 10, 12, 14, 16, 18];
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

  bool get hasLargeDrink {
    for (final log in _todayLogs) {
      final volume = (log['volumeOz'] as num?)?.toDouble() ?? 0;
      if (volume >= 32) return true;
    }
    return false;
  }

  int get smallDrinkCount {
    int count = 0;
    for (final log in _todayLogs) {
      final volume = (log['volumeOz'] as num?)?.toDouble() ?? 0;
      if (volume > 0 && volume < 8) count++;
    }
    return count;
  }
}
