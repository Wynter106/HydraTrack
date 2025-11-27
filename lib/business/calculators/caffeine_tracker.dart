import '../../data/models/beverage.dart';

/// CaffeineTracker - Tracks and calculates caffeine intake
/// 
/// Why do we need this?
/// - FDA recommends max 400mg caffeine per day for adults
/// - Too much caffeine can cause health issues
/// - This tracker helps users stay within safe limits
class CaffeineTracker {
  
  /// Default daily caffeine limit (FDA recommendation)
  static const double defaultDailyLimit = 400; // mg
  
  /// Calculates caffeine from a drink
  /// 
  /// Parameters:
  /// - volumeOz: How much was consumed in ounces
  /// - caffeinePerOz: Caffeine content per ounce (mg/oz)
  /// 
  /// Returns: Total caffeine in mg
  /// 
  /// Formula: caffeine = volumeOz × caffeinePerOz
  static double calculateCaffeine(double volumeOz, double caffeinePerOz) {
    return volumeOz * caffeinePerOz;
  }
  
  /// Calculates caffeine from a Beverage object
  /// 
  /// Parameters:
  /// - beverage: The beverage from database
  /// - volumeOz: How much was consumed (optional, uses default if not provided)
  /// 
  /// Returns: Total caffeine in mg
  static double calculateFromBeverage(Beverage beverage, {double? volumeOz}) {
    final volume = volumeOz ?? beverage.defaultVolumeOz.toDouble();
    return calculateCaffeine(volume, beverage.caffeinePerOz.toDouble());
  }
  
  /// Calculates caffeine percentage towards daily limit
  /// 
  /// Parameters:
  /// - currentCaffeine: How much caffeine consumed today (mg)
  /// - dailyLimit: Maximum recommended caffeine (mg)
  /// 
  /// Returns: Percentage as decimal (0.0 to 1.0+)
  /// 
  /// Example: 200mg current / 400mg limit = 0.5 (50%)
  static double calculateProgress(double currentCaffeine, {double dailyLimit = defaultDailyLimit}) {
    if (dailyLimit <= 0) return 0;
    return currentCaffeine / dailyLimit;
  }
  
  /// Checks if user is approaching caffeine limit (80%+)
  /// 
  /// Parameters:
  /// - currentCaffeine: How much caffeine consumed today (mg)
  /// - dailyLimit: Maximum recommended caffeine (mg)
  /// 
  /// Returns: true if at 80% or more of daily limit
  static bool isNearLimit(double currentCaffeine, {double dailyLimit = defaultDailyLimit}) {
    return calculateProgress(currentCaffeine, dailyLimit: dailyLimit) >= 0.8;
  }
  
  /// Checks if user has exceeded caffeine limit
  /// 
  /// Parameters:
  /// - currentCaffeine: How much caffeine consumed today (mg)
  /// - dailyLimit: Maximum recommended caffeine (mg)
  /// 
  /// Returns: true if over daily limit
  static bool isOverLimit(double currentCaffeine, {double dailyLimit = defaultDailyLimit}) {
    return currentCaffeine > dailyLimit;
  }
  
  /// Calculates how much more caffeine allowed today
  /// 
  /// Parameters:
  /// - currentCaffeine: How much caffeine consumed today (mg)
  /// - dailyLimit: Maximum recommended caffeine (mg)
  /// 
  /// Returns: Remaining caffeine allowed (mg), minimum 0
  static double calculateRemaining(double currentCaffeine, {double dailyLimit = defaultDailyLimit}) {
    final remaining = dailyLimit - currentCaffeine;
    return remaining > 0 ? remaining : 0;
  }
}
