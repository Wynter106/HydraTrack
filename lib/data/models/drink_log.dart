class DrinkLog {
  final String? id;  // Supabase UUID
  final String userId;
  final String beverageName;
  final String? brand;
  final double volumeOz;
  final double caffeineMg;
  final double hydrationContributionOz;
  final DateTime timestamp;

  DrinkLog({
    this.id,
    required this.userId,
    required this.beverageName,
    this.brand,
    required this.volumeOz,
    required this.caffeineMg,
    required this.hydrationContributionOz,
    required this.timestamp,
  });

  // Supabase → Dart
  factory DrinkLog.fromJson(Map<String, dynamic> json) {
    return DrinkLog(
      id: json['id'],
      userId: json['user_id'],
      beverageName: json['beverage_name'],
      brand: json['brand'],
      volumeOz: (json['amount_oz'] as num).toDouble(),
      caffeineMg: (json['caffeine_mg'] as num).toDouble(),
      hydrationContributionOz: (json['hydration_contribution_oz'] as num).toDouble(),
      timestamp: DateTime.parse(json['logged_at']),
    );
  }

  // Dart → Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'beverage_name': beverageName,
      'brand': brand,
      'amount_oz': volumeOz,
      'caffeine_mg': caffeineMg,
      'hydration_contribution_oz': hydrationContributionOz,
      'logged_at': timestamp.toIso8601String(),
    };
  }

  // Original SQLite Code 
  // Delete later
  factory DrinkLog.fromMap(Map<String, dynamic> map) {
    return DrinkLog(
      id: map['id']?.toString(),
      userId: '',
      beverageName: '',
      brand: null,
      volumeOz: map['volume_oz'] as double,
      caffeineMg: 0,
      hydrationContributionOz: map['actual_hydration_oz'] as double,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'volume_oz': volumeOz,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'actual_hydration_oz': hydrationContributionOz,
    };
  }
}