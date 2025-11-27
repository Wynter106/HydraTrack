import '../../data/models/beverage.dart';

/// HydrationCalculator - Calculates actual hydration from beverages
/// 
/// Why do we need this?
/// - Not all drinks hydrate equally
/// - Coffee/tea have caffeine which has diuretic effect
/// - This calculator adjusts hydration based on hydration_factor
/// 
/// Example:
/// - Water: 8oz × 1.0 factor = 8oz actual hydration
/// - Coffee: 8oz × 0.75 factor = 6oz actual hydration
/// - Energy drink: 8oz × 0.6 factor = 4.8oz actual hydration
class HydrationCalculator {
  
  /// Calculates actual hydration from a drink
  /// 
  /// Parameters:
  /// - volumeOz: How much was consumed in ounces
  /// - hydrationFactor: The beverage's hydration efficiency (0.0 to 1.0)
  /// 
  /// Returns: Actual hydration in ounces
  /// 
  /// Formula: actualHydration = volumeOz × hydrationFactor
  static double calculateHydration(double volumeOz, double hydrationFactor) {
    return volumeOz * hydrationFactor;
  }
  
  /// Calculates actual hydration from a Beverage object
  /// 
  /// Parameters:
  /// - beverage: The beverage from database
  /// - volumeOz: How much was consumed (optional, uses default if not provided)
  /// 
  /// Returns: Actual hydration in ounces
  static double calculateFromBeverage(Beverage beverage, {double? volumeOz}) {
    final volume = volumeOz ?? beverage.defaultVolumeOz.toDouble();
    return calculateHydration(volume, beverage.hydrationFactor.toDouble());
  }
  
  /// Calculates hydration percentage towards daily goal
  /// 
  /// Parameters:
  /// - currentHydration: How much hydrated so far today (oz)
  /// - dailyGoal: Target hydration for the day (oz)
  /// 
  /// Returns: Percentage as decimal (0.0 to 1.0+)
  /// 
  /// Example: 32oz current / 64oz goal = 0.5 (50%)
  static double calculateProgress(double currentHydration, double dailyGoal) {
    if (dailyGoal <= 0) return 0;
    return currentHydration / dailyGoal;
  }
  
  /// Calculates how much more hydration needed to reach goal
  /// 
  /// Parameters:
  /// - currentHydration: How much hydrated so far today (oz)
  /// - dailyGoal: Target hydration for the day (oz)
  /// 
  /// Returns: Remaining hydration needed (oz), minimum 0
  static double calculateRemaining(double currentHydration, double dailyGoal) {
    final remaining = dailyGoal - currentHydration;
    return remaining > 0 ? remaining : 0;
  }
}
