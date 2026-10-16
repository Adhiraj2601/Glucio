import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/core/constants/app_constants.dart';
import 'package:glucio/core/utils/sugar_calculator.dart';

void main() {
  group('SugarCalculator - Teaspoons and Cubes Math', () {
    test('converts 0g or negative grams to 0.0 teaspoons', () {
      expect(SugarCalculator.toTeaspoons(0), 0.0);
      expect(SugarCalculator.toTeaspoons(-5), 0.0);
      expect(SugarCalculator.formatTeaspoons(0), '0.0');
    });

    test('converts grams to teaspoons accurately (1 tsp = 4.0g)', () {
      expect(SugarCalculator.toTeaspoons(4.0), 1.0);
      expect(SugarCalculator.toTeaspoons(10.0), 2.5);
      expect(SugarCalculator.toTeaspoons(25.0), 6.25);
      expect(SugarCalculator.formatTeaspoons(SugarCalculator.toTeaspoons(25.0)), '6.3');
      expect(SugarCalculator.formatTeaspoons(SugarCalculator.toTeaspoons(25.5)), '6.4');
    });

    test('toSugarCubes matches toTeaspoons (1 cube = 4.0g = 1 tsp)', () {
      expect(SugarCalculator.toSugarCubes(16.0), 4.0);
      expect(SugarCalculator.toSugarCubes(2.0), 0.5);
    });
  });

  group('SugarCalculator - Daily Limit Percentages', () {
    test('calculates percentage of WHO 25g daily limit correctly', () {
      expect(SugarCalculator.toPercentDailyLimit(0), 0.0);
      expect(SugarCalculator.toPercentDailyLimit(12.5), 50.0);
      expect(SugarCalculator.toPercentDailyLimit(25.0), 100.0);
      expect(SugarCalculator.toPercentDailyLimit(50.0), 200.0);
    });

    test('supports custom daily limits', () {
      expect(SugarCalculator.toPercentDailyLimit(10.0, dailyLimitGrams: 20.0), 50.0);
    });
  });

  group('SugarCalculator - Portion Math', () {
    test('computes portion sugar accurately', () {
      // Parle-G: 25.5g per 100g, serving size 25g
      final servingSugar = SugarCalculator.calculatePortionSugar(
        sugarPer100g: 25.5,
        portionSizeG: 25.0,
      );
      expect(servingSugar, closeTo(6.375, 0.001));

      // Pack size 250g
      final packSugar = SugarCalculator.calculatePortionSugar(
        sugarPer100g: 25.5,
        portionSizeG: 250.0,
      );
      expect(packSugar, closeTo(63.75, 0.001));
    });

    test('returns 0 for non-positive portion or sugar values', () {
      expect(
        SugarCalculator.calculatePortionSugar(sugarPer100g: 0, portionSizeG: 50),
        0.0,
      );
      expect(
        SugarCalculator.calculatePortionSugar(sugarPer100g: 20, portionSizeG: 0),
        0.0,
      );
    });
  });

  group('SugarCalculator - Color and Label Thresholds', () {
    test('returns green for under 50%', () {
      expect(SugarCalculator.getSeverityColor(49.9), AppConstants.sugarLowGreen);
      expect(SugarCalculator.getSeverityLabel(49.9), 'Low Sugar');
    });

    test('returns amber for 50% to 100%', () {
      expect(SugarCalculator.getSeverityColor(50.0), AppConstants.sugarMediumAmber);
      expect(SugarCalculator.getSeverityColor(100.0), AppConstants.sugarMediumAmber);
      expect(SugarCalculator.getSeverityLabel(75.0), 'Moderate Sugar');
    });

    test('returns red for above 100%', () {
      expect(SugarCalculator.getSeverityColor(100.1), AppConstants.sugarHighRed);
      expect(SugarCalculator.getSeverityColor(250.0), AppConstants.sugarHighRed);
      expect(SugarCalculator.getSeverityLabel(150.0), 'High Sugar');
    });
  });

  group('SugarCalculator - Hidden Sugar Detection', () {
    test('flags savory products with sugar >= 5g/100g as hidden sugar', () {
      // Ketchup: category 'sauces', 25.4g/100g
      expect(
        SugarCalculator.isHiddenSugar(
          category: 'sauces',
          sugarPer100g: 25.4,
        ),
        isTrue,
      );

      // Bread: category 'bread', 5.8g/100g
      expect(
        SugarCalculator.isHiddenSugar(
          category: 'bread',
          sugarPer100g: 5.8,
        ),
        isTrue,
      );

      // Instant noodles: category 'instant noodles', 5.5g/100g
      expect(
        SugarCalculator.isHiddenSugar(
          category: 'instant noodles',
          sugarPer100g: 5.5,
        ),
        isTrue,
      );
    });

    test('does not flag savory products with low sugar (< 5g/100g)', () {
      // Haldiram's Alu Bhujia: namkeen, 2.1g/100g
      expect(
        SugarCalculator.isHiddenSugar(
          category: 'namkeen',
          sugarPer100g: 2.1,
        ),
        isFalse,
      );

      // Maggi: instant noodles, 3.2g/100g
      expect(
        SugarCalculator.isHiddenSugar(
          category: 'instant noodles',
          sugarPer100g: 3.2,
        ),
        isFalse,
      );
    });

    test('does not flag sweet categories even if sugar is high unless explicit', () {
      // Biscuits: expected to have sugar, not categorized as hidden
      expect(
        SugarCalculator.isHiddenSugar(
          category: 'biscuits',
          sugarPer100g: 25.5,
        ),
        isFalse,
      );

      // Confectionery
      expect(
        SugarCalculator.isHiddenSugar(
          category: 'confectionery',
          sugarPer100g: 57.0,
        ),
        isFalse,
      );
    });

    test('respects explicit flag even if category is not savory', () {
      expect(
        SugarCalculator.isHiddenSugar(
          category: 'yogurt',
          sugarPer100g: 11.2,
          explicitFlag: true,
        ),
        isTrue,
      );
    });
  });
}
