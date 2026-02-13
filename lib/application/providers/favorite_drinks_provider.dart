import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/favorite_drink.dart';

/// FavoriteDrinksProvider
/// 
/// Manages user's favorite drinks and Quick Add shortcuts.
/// Handles CRUD operations with Supabase and notifies UI of changes.
class FavoriteDrinksProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  // ==================== STATE ====================
  
  List<FavoriteDrink> _favorites = [];
  bool _loading = false;
  
  /// All favorite drinks (read-only)
  List<FavoriteDrink> get favorites => List.unmodifiable(_favorites);
  
  /// Loading state
  bool get loading => _loading;
  
  /// Get only favorites marked for Quick Add
  List<FavoriteDrink> get quickAddFavorites {
    return _favorites.where((fav) => fav.isQuickAdd).toList();
  }
  
  // ==================== LOAD ====================
  
  /// Load all favorites from Supabase
  Future<void> loadFavorites() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('❌ No user logged in');
      return;
    }
    
    _loading = true;
    notifyListeners();
    
    try {
      final data = await _supabase
          .from('favorite_drinks')
          .select()
          .eq('user_id', userId)
          .order('display_order', ascending: true);
      
      _favorites = data
          .map((json) => FavoriteDrink.fromMap(json))
          .toList();
      
      debugPrint('✅ Loaded ${_favorites.length} favorites');
    } catch (e) {
      debugPrint('❌ Error loading favorites: $e');
    }
    
    _loading = false;
    notifyListeners();
  }
  
  // ==================== ADD ====================
  
  /// Add a new favorite drink
  Future<void> addFavorite({
    required String beverageName,
    String? customIcon,
    double? customVolumeOz,
    bool isQuickAdd = false,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      // Calculate new display order (add to end)
      final newOrder = _favorites.isEmpty ? 0 : _favorites.length;
      
      // Insert into Supabase
      final data = await _supabase.from('favorite_drinks').insert({
        'user_id': userId,
        'beverage_name': beverageName,
        'custom_icon': customIcon,
        'custom_volume_oz': customVolumeOz,
        'display_order': newOrder,
        'is_quick_add': isQuickAdd,
      }).select().single();
      
      // Add to local list
      _favorites.add(FavoriteDrink.fromMap(data));
      notifyListeners();
      
      debugPrint('✅ Added favorite: $beverageName');
    } catch (e) {
      debugPrint('❌ Error adding favorite: $e');
      rethrow;
    }
  }
  
  // ==================== TOGGLE FAVORITE ====================
  
  /// Toggle favorite status (star on/off)
  /// Returns true if added, false if removed
  Future<bool> toggleFavorite(String beverageName) async {
    // Check if already favorite
    final existingIndex = _favorites.indexWhere(
      (fav) => fav.beverageName == beverageName,
    );
    
    if (existingIndex != -1) {
      // Already favorite → Remove
      await deleteFavorite(_favorites[existingIndex].id);
      return false;
    } else {
      // Not favorite → Add
      await addFavorite(beverageName: beverageName);
      return true;
    }
  }
  
  /// Check if a beverage is already in favorites
  bool isFavorite(String beverageName) {
    return _favorites.any((fav) => fav.beverageName == beverageName);
  }
  
  // ==================== TOGGLE QUICK ADD ====================
  
  /// Toggle Quick Add status for a favorite
  Future<void> toggleQuickAdd(String favoriteId) async {
    try {
      // Find the favorite
      final index = _favorites.indexWhere((fav) => fav.id == favoriteId);
      if (index == -1) return;
      
      final favorite = _favorites[index];
      final newValue = !favorite.isQuickAdd;
      
      // Update in Supabase
      await _supabase.from('favorite_drinks').update({
        'is_quick_add': newValue,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', favoriteId);
      
      // Update locally
      _favorites[index] = favorite.copyWith(
        isQuickAdd: newValue,
        updatedAt: DateTime.now(),
      );
      
      notifyListeners();
      
      debugPrint('✅ Toggled Quick Add for ${favorite.beverageName}: $newValue');
    } catch (e) {
      debugPrint('❌ Error toggling Quick Add: $e');
      rethrow;
    }
  }
  
  // ==================== UPDATE ====================
  
  /// Update favorite's icon and/or volume
  Future<void> updateFavorite({
    required String id,
    String? customIcon,
    double? customVolumeOz,
  }) async {
    try {
      // Build update map (only include non-null values)
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (customIcon != null) updates['custom_icon'] = customIcon;
      if (customVolumeOz != null) updates['custom_volume_oz'] = customVolumeOz;
      
      // Update in Supabase
      await _supabase
          .from('favorite_drinks')
          .update(updates)
          .eq('id', id);
      
      // Reload to sync
      await loadFavorites();
      
      debugPrint('✅ Updated favorite: $id');
    } catch (e) {
      debugPrint('❌ Error updating favorite: $e');
      rethrow;
    }
  }
  
  // ==================== DELETE ====================
  
  /// Delete a favorite
  Future<void> deleteFavorite(String id) async {
    try {
      // Delete from Supabase
      await _supabase
          .from('favorite_drinks')
          .delete()
          .eq('id', id);
      
      // Remove from local list
      _favorites.removeWhere((fav) => fav.id == id);
      notifyListeners();
      
      debugPrint('✅ Deleted favorite: $id');
    } catch (e) {
      debugPrint('❌ Error deleting favorite: $e');
      rethrow;
    }
  }
  
  // ==================== REORDER ====================
  
  /// Reorder favorites (drag & drop)
  Future<void> reorderFavorites(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    // Reorder locally
    final item = _favorites.removeAt(oldIndex);
    _favorites.insert(newIndex, item);
    
    // Update display_order for all items
    for (int i = 0; i < _favorites.length; i++) {
      _favorites[i] = _favorites[i].copyWith(displayOrder: i);
    }
    
    notifyListeners();
    
    // Save to Supabase
    try {
      for (final fav in _favorites) {
        await _supabase.from('favorite_drinks').update({
          'display_order': fav.displayOrder,
        }).eq('id', fav.id);
      }
      
      debugPrint('✅ Reordered favorites');
    } catch (e) {
      debugPrint('❌ Error reordering: $e');
    }
  }
  
  // ==================== INITIALIZE DEFAULTS ====================
  
  /// Initialize default favorites for first-time users
  Future<void> initializeDefaults() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('❌ No user ID - cannot initialize defaults');
      return;
    }

    try {
      // Double check: Already have favorites in memory?
      if (_favorites.isNotEmpty) {
        debugPrint('✅ Already have ${_favorites.length} favorites in memory, skipping defaults');
        return;
      }

      // Check if user already has favorites in Supabase
      debugPrint('🔍 Checking Supabase for existing favorites...');
      final existing = await _supabase
          .from('favorite_drinks')
          .select()
          .eq('user_id', userId);

      debugPrint('🔍 Found ${existing.length} existing favorites in Supabase');

      if (existing.isNotEmpty) {
        debugPrint('✅ User already has favorites, skipping defaults');
        return;
      }

      debugPrint('🔵 No favorites found, creating defaults...');

      // Default favorites
      final defaults = [
        {
          'beverage_name': 'Water',
          'custom_icon': 'water_drop',
          'custom_volume_oz': 8.0,
        },
        {
          'beverage_name': 'Coffee',
          'custom_icon': 'coffee',
          'custom_volume_oz': 8.0,
        },
        {
          'beverage_name': 'Tea (Green)',
          'custom_icon': 'emoji_food_beverage',
          'custom_volume_oz': 8.0,
        },
        {
          'beverage_name': 'Coca-Cola Classic',
          'custom_icon': 'local_drink',
          'custom_volume_oz': 12.0,
        },
        {
          'beverage_name': 'Red Bull',
          'custom_icon': 'bolt',
          'custom_volume_oz': 8.0,
        },
      ];

      // Insert defaults
      for (int i = 0; i < defaults.length; i++) {
        final inserted = await _supabase.from('favorite_drinks').insert({
          'user_id': userId,
          ...defaults[i],
          'display_order': i,
          'is_quick_add': true,
        }).select().single();

        debugPrint('✅ Inserted: ${inserted['beverage_name']}');
      }

      debugPrint('✅ Initialized ${defaults.length} default favorites');

      // Reload
      await loadFavorites();
    } catch (e) {
      debugPrint('❌ Error initializing defaults: $e');
    }
  }
}