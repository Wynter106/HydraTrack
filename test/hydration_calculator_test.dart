import 'package:flutter_test/flutter_test.dart';
import 'package:hydratrack/business/calculators/hydration_calculator.dart';

void main() {
  group('HydrationCalculator', () {
    group('calculateHydration', () {
      test('water: full hydration factor', () {
        expect(HydrationCalculator.calculateHydration(8.0, 1.0), 8.0);
      });
      test('coffee: 0.75 factor', () {
        expect(HydrationCalculator.calculateHydration(8.0, 0.75), 6.0);
      });
      test('energy drink: 0.6 factor', () {
        expect(HydrationCalculator.calculateHydration(8.0, 0.6), closeTo(4.8, 0.001));
      });
      test('zero volume returns 0', () {
        expect(HydrationCalculator.calculateHydration(0.0, 1.0), 0.0);
      });
    });

    group('calculateProgress', () {
      test('50% progress', () {
        expect(HydrationCalculator.calculateProgress(32.0, 64.0), 0.5);
      });
      test('goal met returns 1.0', () {
        expect(HydrationCalculator.calculateProgress(64.0, 64.0), 1.0);
      });
      test('over goal returns more than 1.0', () {
        expect(HydrationCalculator.calculateProgress(80.0, 64.0), greaterThan(1.0));
      });
      test('zero goal returns 0', () {
        expect(HydrationCalculator.calculateProgress(32.0, 0), 0.0);
      });
    });

    group('calculateRemaining', () {
      test('half way: 32 remaining', () {
        expect(HydrationCalculator.calculateRemaining(32.0, 64.0), 32.0);
      });
      test('goal met: returns 0', () {
        expect(HydrationCalculator.calculateRemaining(64.0, 64.0), 0.0);
      });
      test('over goal: returns 0, not negative', () {
        expect(HydrationCalculator.calculateRemaining(80.0, 64.0), 0.0);
      });
    });
  });
}