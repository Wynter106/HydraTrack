// Database table schemas and constants

class TableNames {
  static const String beverages = 'beverages';
  static const String drinkLogs = 'drink_logs';
  static const String userSettings = 'user_settings';
}

class BeverageColumns {
  static const String id = 'id';
  static const String name = 'name';
  static const String caffeinePerOz = 'caffeine_per_oz';
  static const String hydrationFactor = 'hydration_factor';
  static const String defaultVolumeOz = 'default_volume_oz';
  static const String fav = 'favorite';
}

class DrinkLogColumns {
  static const String id = 'id';
  static const String beverageId = 'beverage_id';
  static const String volumeOz = 'volume_oz';
  static const String timestamp = 'timestamp';
  static const String actualHydrationOz = 'actual_hydration_oz';
}

class UserSettingsColumns {
  static const String id = 'id';
  static const String dailyGoalOz = 'daily_goal_oz';
  static const String heightFeet = 'height_feet';
  static const String heightInches = 'height_inches';
  static const String weightLbs = 'weight_lbs';
  static const String age = 'age';
  static const String gender = 'gender';
}

// SQL CREATE TABLE statements
class TableSchemas {
  static const String createBeveragesTable = '''
    CREATE TABLE ${TableNames.beverages} (
      ${BeverageColumns.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${BeverageColumns.name} TEXT NOT NULL,
      ${BeverageColumns.caffeinePerOz} REAL NOT NULL,
      ${BeverageColumns.hydrationFactor} REAL NOT NULL,
      ${BeverageColumns.defaultVolumeOz} INTEGER NOT NULL
      ${BeverageColumns.fav} BOOLEAN NOT NULL
    )
  ''';

  static const String createDrinkLogsTable = '''
    CREATE TABLE ${TableNames.drinkLogs} (
      ${DrinkLogColumns.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DrinkLogColumns.beverageId} INTEGER NOT NULL,
      ${DrinkLogColumns.volumeOz} REAL NOT NULL,
      ${DrinkLogColumns.timestamp} INTEGER NOT NULL,
      ${DrinkLogColumns.actualHydrationOz} REAL NOT NULL,
      FOREIGN KEY (${DrinkLogColumns.beverageId}) 
        REFERENCES ${TableNames.beverages}(${BeverageColumns.id})
    )
  ''';

  static const String createUserSettingsTable = '''
    CREATE TABLE ${TableNames.userSettings} (
      ${UserSettingsColumns.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${UserSettingsColumns.dailyGoalOz} REAL NOT NULL,
      ${UserSettingsColumns.heightFeet} INTEGER,
      ${UserSettingsColumns.heightInches} INTEGER,
      ${UserSettingsColumns.weightLbs} REAL,
      ${UserSettingsColumns.age} INTEGER,
      ${UserSettingsColumns.gender} TEXT
    )
  ''';

  
}