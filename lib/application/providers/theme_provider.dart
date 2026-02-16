import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  ThemeProvider() {
    _loadThemeFromSupabase();
  }

  /// Load theme from Supabase user profile
  Future<void> _loadThemeFromSupabase() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await _supabase
          .from('profiles')
          .select('theme_mode')
          .eq('id', userId)
          .maybeSingle();

      if (response != null && response['theme_mode'] != null) {
        _themeMode = _stringToThemeMode(response['theme_mode'] as String);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  /// Reload theme (call after login)
  Future<void> reloadTheme() async {
    await _loadThemeFromSupabase();
  }

  /// Set theme mode and save to Supabase
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    await _saveThemeToSupabase(mode);
  }

  /// Save theme preference to Supabase
  Future<void> _saveThemeToSupabase(ThemeMode mode) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('profiles')
          .update({
            'theme_mode': _themeModeToString(mode),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  Future<void> setLightMode() async => await setThemeMode(ThemeMode.light);
  Future<void> setDarkMode() async => await setThemeMode(ThemeMode.dark);
  Future<void> setSystemMode() async => await setThemeMode(ThemeMode.system);

  // Helper methods
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}