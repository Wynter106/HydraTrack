import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/tables.dart';
import '../models/beverage.dart';

class BeverageDao {
  // Get all beverages from database
  // Returns: List of all beverages sorted alphabetically
  Future<List<Beverage>> getAllBeverages() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      TableNames.beverages,
      orderBy: '${BeverageColumns.name} ASC',
    );

    return List.generate(maps.length, (i) => Beverage.fromMap(maps[i]));
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
    final List<Map<String, dynamic>> maps = await db.query(
      TableNames.beverages,
      where: '${BeverageColumns.name} LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: '${BeverageColumns.name} ASC',
    );

    return List.generate(maps.length, (i) => Beverage.fromMap(maps[i]));
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