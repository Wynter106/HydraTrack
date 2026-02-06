import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  
  Future<void> loadProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('No user logged in');
      return;
    }
    
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
      
      print('Profile loaded: goal=$_dailyHydrationGoalOz oz, caffeine=$_dailyCaffeineLimitMg mg');
      
    } catch (e) {
      print('Error loading profile: $e');
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