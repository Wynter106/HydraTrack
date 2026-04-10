import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';
import '../database/tables.dart';
import '../models/beverage.dart';

class BeverageDao {
  // Get all beverages from database
  // Returns: List of all beverages sorted alphabetically
  Future<List<Beverage>> getAllBeverages() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps1 = await db.query(
      TableNames.beverages,
      orderBy: '${BeverageColumns.name} ASC',
    );
    
    final List<Map<String, dynamic>> maps2 = await getMydrinks();

    final maps = [...maps2];
    maps.addAll(maps1);

    return List.generate(maps.length, (i) => Beverage.fromMap(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getMydrinks() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
  
    final response = await supabase
      .from('custom_beverages')
      .select()
      .eq('user_id', userId!);
    
    return response;
  }

  // Get a single beverage by its ID
  // Returns: Beverage object if found, null if not found
  Future<Beverage?> getBeverageById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      TableNames.beverages,
      where: '${BeverageColumns.id} = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Beverage.fromMap(maps.first);
  }

  // Search beverages by name (partial match)
  // Example: "coke" will find "Coca-Cola", "Diet Coke", etc.
  // Returns: List of matching beverages
  Future<List<Beverage>> searchBeverages(String query) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps1 = await db.query(
      TableNames.beverages,
      where: '${BeverageColumns.name} LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: '${BeverageColumns.name} ASC',
    );

    final List<Map<String, dynamic>> maps2 = await getMySearchdrinks(query);
    
    final maps = [...maps2];
    maps.addAll(maps1);

    return List.generate(maps.length, (i) => Beverage.fromMap(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getMySearchdrinks(String query) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
  
    final response = await supabase
      .from('custom_beverages')
      .select()
      .like('name', '%$query%')
      .eq('user_id', userId!);
    
    return response;
  }

  // Get total number of beverages in database
  // Returns: Integer count
  Future<int> getBeverageCount() async {
    final db = await DatabaseHelper.instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${TableNames.beverages}'),
    );
    return count ?? 0;
  }

  Future<List<Beverage>> getAllAlcoholicBeverages() async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  try {
    // Fetch from shared alcohol reference table
    final libResults = await supabase
        .from('alcohol_beverages')
        .select()
        .order('name', ascending: true);

    final libraryBevs = (libResults as List).map((map) {
      return Beverage.fromMap({
        'id': map['id'],
        'name': map['name'],
        'caffeine_per_oz': 0.0,
        'hydration_factor': -0.5,
        'default_volume_oz': map['serving_size_oz'] ?? 12,
        'is_alcoholic': true,
        'abv': map['abv'],
        'serving_size_oz': map['serving_size_oz'],
      });
    }).toList();

    // Also fetch user's custom alcoholic drinks  ← NEW
    List<Beverage> customBevs = [];
    if (userId != null) {
      final customResults = await supabase
          .from('custom_beverages')
          .select()
          .eq('user_id', userId)
          .eq('is_alcoholic', true)
          .order('name', ascending: true);

      customBevs = (customResults as List)
          .map((map) => Beverage.fromMap(map))
          .toList();
    }

    // Custom drinks first so user sees their own at the top
    return [...customBevs, ...libraryBevs];

  } catch (e) {
    return [];
  }
}
  /// Look up an alcoholic drink by exact name
/// Checks alcohol_beverages first, then user's custom alcoholic drinks
Future<Beverage?> getAlcoholicBeverageByExactName(String name) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  try {
    // Check shared alcohol library first
    final libResult = await supabase
        .from('alcohol_beverages')
        .select()
        .eq('name', name)
        .maybeSingle();

    if (libResult != null) {
      return Beverage.fromMap({
        'id': libResult['id'],
        'name': libResult['name'],
        'caffeine_per_oz': 0.0,
        'hydration_factor': -0.5,
        'default_volume_oz': libResult['serving_size_oz'] ?? 12,
        'is_alcoholic': true,
        'abv': libResult['abv'],
        'serving_size_oz': libResult['serving_size_oz'],
      });
    }

    // Fall back to user's custom alcoholic drinks
    if (userId != null) {
      final customResult = await supabase
          .from('custom_beverages')
          .select()
          .eq('user_id', userId)
          .eq('is_alcoholic', true)
          .eq('name', name)
          .maybeSingle();

      if (customResult != null) {
        return Beverage.fromMap(customResult);
      }
    }

    return null;
  } catch (e) {
    return null;
  }
}


  Future<List<Beverage>> searchAlcoholicBeverages(String query) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    try {
      final libResults = await supabase
          .from('alcohol_beverages')
          .select()
          .ilike('name', '%$query%')
          .order('name', ascending: true);

      final libraryBevs = (libResults as List).map((map) {
        return Beverage.fromMap({
          'id': map['id'],
          'name': map['name'],
          'caffeine_per_oz': 0.0,
          'hydration_factor': -0.5,
          'default_volume_oz': map['serving_size_oz'] ?? 12,
          'is_alcoholic': true,
          'abv': map['abv'],
          'serving_size_oz': map['serving_size_oz'],
        });
      }).toList();

      List<Beverage> customBevs = [];
      if (userId != null) {
        final customResults = await supabase
            .from('custom_beverages')
            .select()
            .eq('user_id', userId)
            .eq('is_alcoholic', true)
            .ilike('name', '%$query%');
        customBevs = (customResults as List)
            .map((map) => Beverage.fromMap(map))
            .toList();
      }

      return [...customBevs, ...libraryBevs];
    } catch (e) {
      return [];
    }
  }

  /// Get beverage by exact name match
  /// Use this for Quick Add buttons where we know the exact name
  Future<Beverage?> getBeverageByExactName(String name) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      TableNames.beverages,
      where: '${BeverageColumns.name} = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Beverage.fromMap(maps.first);
  }
}