// Class to record a single instance of a drink consumption.
// e.g., "At 14:30, consumed 250ml of Coffee, resulting in 187ml of hydration and 95mg of caffeine."
// 
// fromMap: DB -> Dart Object (Deserialization)
// toMap: Dart Object -> DB (Serialization)
class DrinkLog {
  final int? id;              // Unique log ID
  final int beverageId;       // ID of the consumed beverage (foreign key to 'beverages' table)
  final String beverageName;  // Beverage name (for display purposes)
  final double volumeOz;      // Volume consumed (in oz)
  final DateTime timestamp;   // Time the drink was consumed
  final double hydrationOz;   // Actual hydration amount (calculated value in oz)
  final double caffeineMg;    // Caffeine amount (calculated value in mg)

  DrinkLog({
    this.id,
    required this.beverageId,
    required this.beverageName,
    required this.volumeOz,
    required this.timestamp,
    required this.hydrationOz,
    required this.caffeineMg,
  });

  /// Converts a Map (from the DB) into a DrinkLog object.
  factory DrinkLog.fromMap(Map<String, dynamic> map) {
    return DrinkLog(
      id: map['id'] as int?,
      beverageId: map['beverage_id'] as int,
      beverageName: map['beverage_name'] as String,
      volumeOz: map['volume_oz'] as double,
      timestamp: DateTime.parse(map['timestamp'] as String),
      hydrationOz: map['hydration_oz'] as double,
      caffeineMg: map['caffeine_mg'] as double,
    );
  }

/// Converts the DrinkLog object into a Map suitable for DB storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'beverage_id': beverageId,
      'beverage_name': beverageName,
      'volume_oz': volumeOz,
      'timestamp': timestamp.toIso8601String(),
      'hydration_oz': hydrationOz,
      'caffeine_mg': caffeineMg,
    };
  }
}