/// Class to hold user-specific configuration and settings.
class UserSettings {
final int? id;
   final double heightIn;             // Height in inches (in)
  final double weightLb;              // Weight in pounds (lb)
  final double dailyGoalOz;           // Daily hydration goal (oz)
  final bool notificationsEnabled;    // Flag to enable/disable notifications
  final DateTime? lastModified;       // Timestamp of the last modification

  UserSettings({
    this.id,
    required this.heightIn,
    required this.weightLb,
    required this.dailyGoalOz,
    this.notificationsEnabled = false,
    this.lastModified,
  });

  /// Converts a Map (from the DB) into a UserSettings object.
  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      id: map['id'] as int?,
      heightIn: map['height_in'] as double,
      weightLb: map['weight_lb'] as double,
      dailyGoalOz: map['daily_goal_oz'] as double,
      notificationsEnabled: (map['notifications_enabled'] as int) == 1,
      lastModified: map['last_modified'] != null
          ? DateTime.parse(map['last_modified'] as String)
          : null,
    );
  }

  /// Converts the UserSettings object into a Map suitable for DB storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'height_in': heightIn,
      'weight_lb': weightLb,
      'daily_goal_oz': dailyGoalOz,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'last_modified': lastModified?.toIso8601String() ?? 
                       DateTime.now().toIso8601String(),
    };
  }

  /// Provides standard/initial settings when a new user starts the app.
  factory UserSettings.defaultSettings() {
    return UserSettings(
      heightIn: 67.0,      // 5'7" (Average height)
      weightLb: 154.0,     // Approx. 70kg
      dailyGoalOz: 64.0,   // Approx. 2 Liters
      notificationsEnabled: false,
    );
  }

  // --- UI Convenience Methods ---
  /// Calculates the height's feet component.
  int get heightFeet => heightIn ~/ 12;

  /// Calculates the remaining inches component.
  int get heightInchesRemaining => (heightIn % 12).toInt();
  
  /// Formats the height into standard feet and inches (e.g., "5'7\"").
  String get heightFormatted => "$heightFeet'$heightInchesRemaining\"";
}
