// Class to record a single instance of a drink consumption.
// e.g., "At 14:30, consumed 250ml of Coffee, resulting in 187ml of hydration and 95mg of caffeine."
// 
// fromMap: DB -> Dart Object (Deserialization)
// toMap: Dart Object -> DB (Serialization)
class DrinkLog {
  final int? id;
  final int beverageId;       // Foreign key to beverages table
  final double volumeOz;      // Volume consumed (in oz)
  final DateTime timestamp;   // Time the drink was consumed
  final double actualHydrationOz;  // Actual hydration amount (in oz)

  DrinkLog({
    this.id,
    required this.beverageId,
    required this.volumeOz,
    required this.timestamp,
    required this.actualHydrationOz,
  });

  /// Converts a Map (from the DB) into a DrinkLog object.
  factory DrinkLog.fromMap(Map<String, dynamic> map) {
    return DrinkLog(
      id: map['id'] as int?,
      beverageId: map['beverage_id'] as int,
      volumeOz: map['volume_oz'] as double,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      actualHydrationOz: map['actual_hydration_oz'] as double,
    );
  }

/// Converts the DrinkLog object into a Map suitable for DB storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'beverage_id': beverageId,
      'volume_oz': volumeOz,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'actual_hydration_oz': actualHydrationOz,
    };
  }
}