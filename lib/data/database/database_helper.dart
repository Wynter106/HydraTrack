import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'tables.dart';
import 'beverages_seed.dart';

class DatabaseHelper {
  // Singleton pattern - only one instance of database helper
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  // Get database instance (create if doesn't exist)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    // Get the default database path
    String path = join(await getDatabasesPath(), 'hydratrack.db');

    // Open database (creates if doesn't exist)
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Called when database is created for the first time
  Future<void> _onCreate(Database db, int version) async {
    
    print('🔍 Creating beverages table with SQL:');
    print(TableSchemas.createBeveragesTable);
    print('🔍 End of SQL');
    
    // Create all tables
    await db.execute(TableSchemas.createBeveragesTable);
    await db.execute(TableSchemas.createDrinkLogsTable);
    await db.execute(TableSchemas.createUserSettingsTable);

    // Insert seed data for beverages
    await _insertSeedData(db);

    print('✅ Database created with all tables and seed data');
  }

  // Called when database needs to be upgraded to new version
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    // Example: if (oldVersion < 2) { ... }
    print('Database upgraded from v$oldVersion to v$newVersion');
  }

  // Insert all seed beverage data
  Future<void> _insertSeedData(Database db) async {
    try {
      // Insert all beverages from the unified seed list
      for (var beverage in beveragesSeed) {
        await db.insert(
          TableNames.beverages,
          {
            BeverageColumns.name: beverage['name'],
            BeverageColumns.caffeinePerOz: beverage['caffeine_per_oz'],
            BeverageColumns.hydrationFactor: beverage['hydration_factor'],
            BeverageColumns.defaultVolumeOz: beverage['default_volume_oz'],
            BeverageColumns.fav: beverage['favorite'],
          },
        );
      }

      print('✅ Seed data inserted successfully (${beveragesSeed.length} beverages)');
    } catch (e) {
      print('❌ Error inserting seed data: $e');
      rethrow;
    }
  }

  // Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // Delete database (useful for testing)
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'hydratrack.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
    print('🗑️ Database deleted');
  }
}