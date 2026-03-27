import 'package:flutter_test/flutter_test.dart';
import 'package:hydratrack/business/calculators/caffeine_tracker.dart';

void main() {
  group('CaffeineTracker', () {
    group('calculateCaffeine', () {
      test('basic calculation', () {
        expect(CaffeineTracker.calculateCaffeine(8.0, 12.5), 100.0);
      });
      test('zero volume returns 0', () {
        expect(CaffeineTracker.calculateCaffeine(0.0, 12.5), 0.0);
      });
      test('caffeine-free drink returns 0', () {
        expect(CaffeineTracker.calculateCaffeine(8.0, 0.0), 0.0);
      });
    });

    group('calculateProgress', () {
      test('50% of default limit (400mg)', () {
        expect(CaffeineTracker.calculateProgress(200.0), 0.5);
      });
      test('custom limit', () {
        expect(CaffeineTracker.calculateProgress(100.0, dailyLimit: 200.0), 0.5);
      });
      test('zero limit returns 0', () {
        expect(CaffeineTracker.calculateProgress(100.0, dailyLimit: 0), 0.0);
      });
    });

    group('isNearLimit', () {
      test('320mg out of 400mg = 80%, should be near limit', () {
        expect(CaffeineTracker.isNearLimit(320.0), isTrue);
      });
      test('319mg = just under 80%, not near limit', () {
        expect(CaffeineTracker.isNearLimit(319.0), isFalse);
      });
      test('over limit also counts as near limit', () {
        expect(CaffeineTracker.isNearLimit(500.0), isTrue);
      });
    });

    group('isOverLimit', () {
      test('401mg is over default limit', () {
        expect(CaffeineTracker.isOverLimit(401.0), isTrue);
      });
      test('400mg is not over (exactly at limit)', () {
        expect(CaffeineTracker.isOverLimit(400.0), isFalse);
      });
      test('custom limit', () {
        expect(CaffeineTracker.isOverLimit(201.0, dailyLimit: 200.0), isTrue);
      });
    });

    group('calculateRemaining', () {
      test('200mg consumed, 200mg remaining', () {
        expect(CaffeineTracker.calculateRemaining(200.0), 200.0);
      });
      test('over limit returns 0, not negative', () {
        expect(CaffeineTracker.calculateRemaining(500.0), 0.0);
      });
    });
  });
}