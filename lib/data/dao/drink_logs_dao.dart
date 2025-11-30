import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/tables.dart';
import '../models/drink_log.dart';

/// Data Access Object for the drink_logs table.
class DrinkLogDao {
  /// Insert a new drink log into the database.
  Future<int> insertDrinkLog(DrinkLog log) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert(
      TableNames.drinkLogs,
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all drink logs (mostly for debugging).
  Future<List<DrinkLog>> getAllLogs() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      TableNames.drinkLogs,
      orderBy: '${DrinkLogColumns.timestamp} ASC',
    );

    return List.generate(maps.length, (i) => DrinkLog.fromMap(maps[i]));
  }

  /// Returns all logs for a single calendar day (midnight → midnight).
  Future<List<DrinkLog>> getLogsForDay(DateTime day) async {
    final db = await DatabaseHelper.instance.database;

    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      TableNames.drinkLogs,
      where:
          '${DrinkLogColumns.timestamp} >= ? AND ${DrinkLogColumns.timestamp} < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: '${DrinkLogColumns.timestamp} ASC',
    );

    return List.generate(maps.length, (i) => DrinkLog.fromMap(maps[i]));
  }

  /// Sum of actual hydration (oz) for a single day.
  Future<double> getTotalHydrationOzForDay(DateTime day) async {
    final logs = await getLogsForDay(day);
    double total = 0;
    for (final log in logs) {
      total += log.actualHydrationOz;
    }
    return total;
  }

  /// Number of consecutive days (up to maxDays) where the user
  /// met or exceeded dailyGoalOz, counting backward from today.
  Future<int> getStreakCount(double dailyGoalOz, {int maxDays = 365}) async {
    int streak = 0;
    DateTime day = DateTime.now();

    for (int i = 0; i < maxDays; i++) {
      final total = await getTotalHydrationOzForDay(day);
      if (total + 1e-6 < dailyGoalOz) {
        // Below goal → streak ends
        break;
      }
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
