import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/glucio_theme.dart';

/// Pure utility class for nutrition and sugar calculations.
///
/// Designed to keep math simple, fully testable, and transparent.
/// Strictly enforces that missing/unknown sugar values are null, NEVER defaulted to 0.
class SugarCalculator {
  SugarCalculator._();

  /// Converts grams of sugar into raw teaspoons (1 tsp = 4.0g).
  /// Returns null if [grams] is null.
  static double? toTeaspoons(double? grams) {
    if (grams == null) return null;
    if (grams <= 0) return 0.0;
    return grams / AppConstants.gramsPerTeaspoon;
  }

  /// Plain-language rounding for display:
  /// - 0: "No sugar" (if verified zero)
  /// - 0.1 to 0.3: "less than ¼ teaspoon"
  /// - 0.4 to 0.6: "about ½ teaspoon"
  /// - 0.7 to 0.85: "about ¾ teaspoon"
  /// - 0.9 to 1.15: "about 1 teaspoon"
  /// - > 1.15: round to nearest half or quarter with simple glyphs (1½, 2¼, 3)
  static String formatTeaspoonsPlain(double? teaspoons, {bool isVerifiedZero = false}) {
    if (teaspoons == null) return 'Sugar data missing';
    if (teaspoons <= 0.05) {
      return isVerifiedZero ? 'No sugar' : 'less than ¼ teaspoon';
    }

    if (teaspoons <= 0.30) {
      return 'less than ¼ teaspoon';
    } else if (teaspoons <= 0.65) {
      return 'about ½ teaspoon';
    } else if (teaspoons <= 0.875) {
      return 'about ¾ teaspoon';
    } else if (teaspoons <= 1.15) {
      return 'about 1 teaspoon';
    }

    // > 1.15: round to nearest quarter (0.25)
    final rounded = (teaspoons * 4).round() / 4.0;
    final whole = rounded.floor();
    final fraction = rounded - whole;

    String fractionGlyph = '';
    if ((fraction - 0.25).abs() < 0.01) {
      fractionGlyph = '¼';
    } else if ((fraction - 0.50).abs() < 0.01) {
      fractionGlyph = '½';
    } else if ((fraction - 0.75).abs() < 0.01) {
      fractionGlyph = '¾';
    }

    if (fractionGlyph.isEmpty) {
      return 'about $whole ${whole == 1 ? "teaspoon" : "teaspoons"}';
    } else if (whole == 0) {
      return 'about $fractionGlyph teaspoon';
    } else {
      return 'about $whole$fractionGlyph teaspoons';
    }
  }

  /// Calculates the percentage of the WHO recommended daily limit (default 25g).
  /// Returns null if [grams] is null.
  static double? toPercentDailyLimit(
    double? grams, {
    double dailyLimitGrams = AppConstants.defaultDailySugarLimitGrams,
  }) {
    if (grams == null) return null;
    if (grams <= 0 || dailyLimitGrams <= 0) return 0.0;
    return (grams / dailyLimitGrams) * 100.0;
  }

  /// Computes the sugar grams for a given portion amount and multiplier.
  /// Formula: (sugarPer100 * amount * multiplier) / 100
  /// Returns null if [sugarPer100] is null.
  static double? calculatePortionSugar({
    required double? sugarPer100,
    required double portionAmount,
    int multiplier = 1,
  }) {
    if (sugarPer100 == null) return null;
    if (sugarPer100 <= 0 || portionAmount <= 0 || multiplier <= 0) return 0.0;
    return (sugarPer100 * portionAmount * multiplier) / 100.0;
  }

  /// Returns the UI color corresponding to the % of daily limit consumed.
  /// - null: GlucioTheme.levelMissing (neutral gray)
  /// - <= 25%: GlucioTheme.levelLow (green)
  /// - 26% - 50%: GlucioTheme.levelMedium (amber)
  /// - > 50%: GlucioTheme.levelHigh (coral/red)
  static Color getSeverityColor(double? percent) {
    if (percent == null) return GlucioTheme.levelMissing;
    if (percent <= 25.0) {
      return GlucioTheme.levelLow;
    } else if (percent <= 50.0) {
      return GlucioTheme.levelMedium;
    } else {
      return GlucioTheme.levelHigh;
    }
  }

  /// Returns a human-friendly severity label based on percentage of daily limit.
  static String getSeverityLabel(double? percent) {
    if (percent == null) return 'Sugar Data Missing';
    if (percent <= 25.0) {
      return 'Low Sugar';
    } else if (percent <= 50.0) {
      return 'Moderate Sugar';
    } else {
      return 'High Sugar';
    }
  }

  /// Detects whether sugar is hidden in an unexpectedly savory product.
  /// Only applies if sugar is known.
  static bool isHiddenSugar({
    required String category,
    required double? sugarPer100,
    bool explicitFlag = false,
  }) {
    if (explicitFlag) return true;
    if (sugarPer100 == null) return false;
    final cat = category.trim().toLowerCase();
    final isSavory = AppConstants.savoryCategories.any(
      (c) => cat.contains(c),
    );
    return isSavory && sugarPer100 >= AppConstants.hiddenSugarSavoryThresholdGrams;
  }
}
