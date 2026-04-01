import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  int _dailyHydrationGoalOz = 67;
  int _dailyCaffeineLimitMg = 400;
  String _preferredVolumeUnit = 'oz';
  bool _loading = false;
  
  // Getters
  int get dailyHydrationGoalOz => _dailyHydrationGoalOz;
  int get dailyCaffeineLimitMg => _dailyCaffeineLimitMg;
  String get preferredVolumeUnit => _preferredVolumeUnit;
  bool get loading => _loading;
  
  // unit change
  double get dailyGoalInPreferredUnit {
    if (_preferredVolumeUnit == 'ml') {
      return _dailyHydrationGoalOz * 29.5735;
    }
    return _dailyHydrationGoalOz.toDouble();
  }
  
  String get dailyGoalDisplay {
    if (_preferredVolumeUnit == 'ml') {
      return '${dailyGoalInPreferredUnit.round()} ml';
    }
    return '$_dailyHydrationGoalOz oz';
  }
  
  static const _kGoalKey = 'cached_goal_oz';
  static const _kCaffeineKey = 'cached_caffeine_mg';
  static const _kUnitKey = 'cached_volume_unit';

  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kGoalKey, _dailyHydrationGoalOz);
    await prefs.setInt(_kCaffeineKey, _dailyCaffeineLimitMg);
    await prefs.setString(_kUnitKey, _preferredVolumeUnit);
  }

  Future<void> loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyHydrationGoalOz = prefs.getInt(_kGoalKey) ?? 67;
    _dailyCaffeineLimitMg = prefs.getInt(_kCaffeineKey) ?? 400;
    _preferredVolumeUnit = prefs.getString(_kUnitKey) ?? 'oz';
    notifyListeners();
  }

  Future<void> loadProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _loading = true;
    notifyListeners();

    try {
      final profile = await _supabase
          .from('profiles')
          .select('daily_hydration_goal_oz, daily_caffeine_limit_mg, preferred_volume_unit')
          .eq('id', userId)
          .single();

      _dailyHydrationGoalOz = profile['daily_hydration_goal_oz'] ?? 67;
      _dailyCaffeineLimitMg = profile['daily_caffeine_limit_mg'] ?? 400;
      _preferredVolumeUnit = profile['preferred_volume_unit'] ?? 'oz';

      await _saveToCache(); // ← 성공하면 캐시 저장
    } catch (e) {
      debugPrint('Offline or error — loading profile from cache: $e');
      await loadFromCache(); // ← 실패하면 캐시에서 로드
    }

    _loading = false;
    notifyListeners();
  }
  
  Future<void> updateVolumeUnit(String newUnit) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      await _supabase
          .from('profiles')
          .update({'preferred_volume_unit': newUnit})
          .eq('id', userId);
      
      _preferredVolumeUnit = newUnit;
      notifyListeners();
    } catch (e) {
      print('Error updating volume unit: $e');
    }
  }
}