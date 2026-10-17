import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/core/theme/glucio_theme.dart';
import 'package:glucio/core/utils/sugar_calculator.dart';

void main() {
  group('SugarCalculator - Teaspoons Math & Null Handling', () {
    test('returns null when grams is null', () {
      expect(SugarCalculator.toTeaspoons(null), isNull);
    });

    test('converts 0g or negative grams to 0.0 teaspoons', () {
      expect(SugarCalculator.toTeaspoons(0), 0.0);
      expect(SugarCalculator.toTeaspoons(-5), 0.0);
    });

    test('converts grams to teaspoons accurately (1 tsp = 4.0g)', () {
      expect(SugarCalculator.toTeaspoons(4.0), 1.0);
      expect(SugarCalculator.toTeaspoons(10.0), 2.5);
      expect(SugarCalculator.toTeaspoons(25.0), 6.25);
    });
  });

  group('SugarCalculator - Plain-Language Teaspoons Rounding', () {
    test('handles null teaspoons', () {
      expect(SugarCalculator.formatTeaspoonsPlain(null), 'Sugar data missing');
    });

    test('handles verified zero vs unverified zero', () {
      expect(SugarCalculator.formatTeaspoonsPlain(0.0, isVerifiedZero: true), 'No sugar');
      expect(SugarCalculator.formatTeaspoonsPlain(0.0, isVerifiedZero: false), 'less than ¼ teaspoon');
    });

    test('formats small amounts (< 0.18 tsp) as less than ¼ teaspoon', () {
      expect(SugarCalculator.formatTeaspoonsPlain(0.15), 'less than ¼ teaspoon');
    });

    test('formats quarter teaspoon (0.18 - 0.29)', () {
      expect(SugarCalculator.formatTeaspoonsPlain(0.25), 'about ¼ teaspoon');
    });

    test('formats one third teaspoon (0.29 - 0.42), e.g. 1.3g ketchup (0.325 tsp)', () {
      expect(SugarCalculator.formatTeaspoonsPlain(0.325), 'about ⅓ teaspoon');
    });

    test('formats half teaspoon (0.42 - 0.58) without rounding up early', () {
      expect(SugarCalculator.formatTeaspoonsPlain(0.5), 'about ½ teaspoon');
    });

    test('formats two thirds teaspoon (0.58 - 0.71)', () {
      expect(SugarCalculator.formatTeaspoonsPlain(0.667), 'about ⅔ teaspoon');
    });

    test('formats three quarters teaspoon (0.71 - 0.88)', () {
      expect(SugarCalculator.formatTeaspoonsPlain(0.75), 'about ¾ teaspoon');
    });

    test('formats 1 teaspoon (0.88 - 1.15)', () {
      expect(SugarCalculator.formatTeaspoonsPlain(1.0), 'about 1 teaspoon');
      expect(SugarCalculator.formatTeaspoonsPlain(1.1), 'about 1 teaspoon');
    });

    test('formats fractions > 1.15 with glyphs (1⅓, 1½, 2¼, 3)', () {
      expect(SugarCalculator.formatTeaspoonsPlain(1.33), 'about 1⅓ teaspoons');
      expect(SugarCalculator.formatTeaspoonsPlain(1.5), 'about 1½ teaspoons');
      expect(SugarCalculator.formatTeaspoonsPlain(2.25), 'about 2¼ teaspoons');
      expect(SugarCalculator.formatTeaspoonsPlain(3.0), 'about 3 teaspoons');
      expect(SugarCalculator.formatTeaspoonsPlain(3.75), 'about 3¾ teaspoons');
    });
  });

  group('SugarCalculator - Food Sugar Density (Per 100g/ml)', () {
    test('grades solids correctly based on 5g/20g thresholds', () {
      expect(SugarCalculator.getFoodSugarDensityLabel(2.1), 'Low Sugar');
      expect(SugarCalculator.getFoodSugarDensityLabel(12.0), 'Moderate Sugar');
      expect(SugarCalculator.getFoodSugarDensityLabel(25.4), 'High Sugar');
      expect(SugarCalculator.getFoodSugarDensityLabel(null), 'Sugar Data Missing');
    });

    test('grades liquids correctly based on 2.5g/10g thresholds', () {
      expect(SugarCalculator.getFoodSugarDensityLabel(2.0, isLiquid: true), 'Low Sugar');
      expect(SugarCalculator.getFoodSugarDensityLabel(6.0, isLiquid: true), 'Moderate Sugar');
      expect(SugarCalculator.getFoodSugarDensityLabel(10.6, isLiquid: true), 'High Sugar');
    });
  });

  group('SugarCalculator - Daily Limit Percentages', () {
    test('returns null when grams is null', () {
      expect(SugarCalculator.toPercentDailyLimit(null), isNull);
    });

    test('calculates percentage of WHO 25g daily limit correctly', () {
      expect(SugarCalculator.toPercentDailyLimit(0), 0.0);
      expect(SugarCalculator.toPercentDailyLimit(6.25), 25.0);
      expect(SugarCalculator.toPercentDailyLimit(12.5), 50.0);
      expect(SugarCalculator.toPercentDailyLimit(25.0), 100.0);
      expect(SugarCalculator.toPercentDailyLimit(50.0), 200.0);
    });

    test('supports custom daily limits', () {
      expect(SugarCalculator.toPercentDailyLimit(10.0, dailyLimitGrams: 20.0), 50.0);
    });
  });

  group('SugarCalculator - Portion Math & Multiplier', () {
    test('returns null when sugarPer100 is null', () {
      expect(
        SugarCalculator.calculatePortionSugar(
          sugarPer100: null,
          portionAmount: 30.0,
        ),
        isNull,
      );
    });

    test('computes portion sugar accurately with x1, x2, x3 multipliers', () {
      // Parle-G: 25.5g per 100g, portion size 25g
      final x1 = SugarCalculator.calculatePortionSugar(
        sugarPer100: 25.5,
        portionAmount: 25.0,
        multiplier: 1,
      );
      expect(x1, closeTo(6.375, 0.001));

      final x2 = SugarCalculator.calculatePortionSugar(
        sugarPer100: 25.5,
        portionAmount: 25.0,
        multiplier: 2,
      );
      expect(x2, closeTo(12.75, 0.001));

      final x3 = SugarCalculator.calculatePortionSugar(
        sugarPer100: 25.5,
        portionAmount: 25.0,
        multiplier: 3,
      );
      expect(x3, closeTo(19.125, 0.001));
    });

    test('returns 0 for non-positive portion or sugar values', () {
      expect(
        SugarCalculator.calculatePortionSugar(sugarPer100: 0, portionAmount: 50),
        0.0,
      );
      expect(
        SugarCalculator.calculatePortionSugar(sugarPer100: 20, portionAmount: 0),
        0.0,
      );
    });
  });

  group('SugarCalculator - Color and Label Thresholds', () {
    test('returns neutral gray for null percent', () {
      expect(SugarCalculator.getSeverityColor(null), GlucioTheme.levelMissing);
      expect(SugarCalculator.getSeverityLabel(null), 'Sugar Data Missing');
    });

    test('returns green (Low Sugar) for <= 25%', () {
      expect(SugarCalculator.getSeverityColor(10.0), GlucioTheme.levelLow);
      expect(SugarCalculator.getSeverityColor(25.0), GlucioTheme.levelLow);
      expect(SugarCalculator.getSeverityLabel(25.0), 'Low Sugar');
    });

    test('returns amber (Moderate Sugar) for 26% to 50%', () {
      expect(SugarCalculator.getSeverityColor(26.0), GlucioTheme.levelMedium);
      expect(SugarCalculator.getSeverityColor(50.0), GlucioTheme.levelMedium);
      expect(SugarCalculator.getSeverityLabel(40.0), 'Moderate Sugar');
    });

    test('returns red (High Sugar) for above 50%', () {
      expect(SugarCalculator.getSeverityColor(50.1), GlucioTheme.levelHigh);
      expect(SugarCalculator.getSeverityColor(120.0), GlucioTheme.levelHigh);
      expect(SugarCalculator.getSeverityLabel(75.0), 'High Sugar');
    });
  });

  group('SugarCalculator - Hidden Sugar Detection', () {
    test('returns false when sugar is null', () {
      expect(
        SugarCalculator.isHiddenSugar(
          category: 'sauces',
          sugarPer100: null,
        ),
        isFalse,
      );
    });

    test('flags savory products with sugar >= 5g/100g as hidden sugar', () {
      // Ketchup: category 'sauces', 25.4g/100g
      expect(
        SugarCalculator.isHiddenSugar(
          category: 'sauces',
          sugarPer100: 25.4,
        ),
        isTrue,
      );

      // Bread: category 'bread', 5.8g/100g
      expect(
        SugarCalculator.isHiddenSugar(
          category: 'bread',
          sugarPer100: 5.8,
        ),
        isTrue,
      );
    });

    test('does not flag savory products with low sugar (< 5g/100g)', () {
      // Haldiram's Alu Bhujia: namkeen, 2.1g/100g
      expect(
        SugarCalculator.isHiddenSugar(
          category: 'namkeen',
          sugarPer100: 2.1,
        ),
        isFalse,
      );
    });

    test('does not flag sweet categories unless explicit', () {
      // Biscuits
      expect(
        SugarCalculator.isHiddenSugar(
          category: 'biscuits',
          sugarPer100: 25.5,
        ),
        isFalse,
      );
    });

    test('respects explicit flag even if category is not savory or sugar is null', () {
      expect(
        SugarCalculator.isHiddenSugar(
          category: 'yogurt',
          sugarPer100: null,
          explicitFlag: true,
        ),
        isTrue,
      );
    });
  });
}
