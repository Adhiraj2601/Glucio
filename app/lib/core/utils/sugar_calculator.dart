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
  /// - < 0.18: "less than ¼ teaspoon"
  /// - 0.18 to 0.29: "about ¼ teaspoon"
  /// - 0.29 to 0.42: "about ⅓ teaspoon" (e.g. 1.3g ketchup -> 0.325 tsp)
  /// - 0.42 to 0.58: "about ½ teaspoon" (only rounds to half when truly closer)
  /// - 0.58 to 0.71: "about ⅔ teaspoon"
  /// - 0.71 to 0.88: "about ¾ teaspoon"
  /// - 0.88 to 1.15: "about 1 teaspoon"
  /// - > 1.15: round to nearest whole or fractional glyph (¼, ⅓, ½, ⅔, ¾)
  static String formatTeaspoonsPlain(double? teaspoons, {bool isVerifiedZero = false}) {
    if (teaspoons == null) return 'Sugar data missing';
    if (teaspoons <= 0.05) {
      return isVerifiedZero ? 'No sugar' : 'less than ¼ teaspoon';
    }

    if (teaspoons < 0.18) {
      return 'less than ¼ teaspoon';
    } else if (teaspoons < 0.29) {
      return 'about ¼ teaspoon';
    } else if (teaspoons < 0.42) {
      return 'about ⅓ teaspoon';
    } else if (teaspoons < 0.58) {
      return 'about ½ teaspoon';
    } else if (teaspoons < 0.71) {
      return 'about ⅔ teaspoon';
    } else if (teaspoons < 0.88) {
      return 'about ¾ teaspoon';
    } else if (teaspoons <= 1.15) {
      return 'about 1 teaspoon';
    }

    // > 1.15: find nearest candidate among whole, ¼, ⅓, ½, ⅔, ¾
    final whole = teaspoons.floor();
    final fraction = teaspoons - whole;

    const candidates = [
      (0.0, ''),
      (0.25, '¼'),
      (1.0 / 3.0, '⅓'),
      (0.50, '½'),
      (2.0 / 3.0, '⅔'),
      (0.75, '¾'),
      (1.0, 'NEXT_WHOLE'),
    ];

    double minDiff = 999.0;
    String bestGlyph = '';
    int adjustedWhole = whole;

    for (final candidate in candidates) {
      final diff = (fraction - candidate.$1).abs();
      if (diff < minDiff) {
        minDiff = diff;
        if (candidate.$2 == 'NEXT_WHOLE') {
          adjustedWhole = whole + 1;
          bestGlyph = '';
        } else {
          adjustedWhole = whole;
          bestGlyph = candidate.$2;
        }
      }
    }

    if (bestGlyph.isEmpty) {
      return 'about $adjustedWhole ${adjustedWhole == 1 ? "teaspoon" : "teaspoons"}';
    } else if (adjustedWhole == 0) {
      return 'about $bestGlyph teaspoon';
    } else {
      return 'about $adjustedWhole$bestGlyph teaspoons';
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

  /// Categorizes food sugar density based on per-100g (or per-100ml) nutritional content.
  /// Standard international and Indian FSSAI traffic light criteria:
  /// - Low Sugar: <= 5g/100g (or <= 2.5g/100ml for liquids)
  /// - Moderate Sugar: > 5g and <= 20g/100g (or > 2.5g and <= 10g/100ml for liquids)
  /// - High Sugar: > 20g/100g (or > 10g/100ml for liquids)
  static String getFoodSugarDensityLabel(double? sugarPer100, {bool isLiquid = false}) {
    if (sugarPer100 == null) return 'Sugar Data Missing';
    final lowCutoff = isLiquid ? 2.5 : 5.0;
    final highCutoff = isLiquid ? 10.0 : 20.0;

    if (sugarPer100 <= lowCutoff) {
      return 'Low Sugar';
    } else if (sugarPer100 <= highCutoff) {
      return 'Moderate Sugar';
    } else {
      return 'High Sugar';
    }
  }

  /// Returns the color associated with the food sugar density rating.
  static Color getFoodSugarDensityColor(double? sugarPer100, {bool isLiquid = false}) {
    if (sugarPer100 == null) return GlucioTheme.levelMissing;
    final lowCutoff = isLiquid ? 2.5 : 5.0;
    final highCutoff = isLiquid ? 10.0 : 20.0;

    if (sugarPer100 <= lowCutoff) {
      return GlucioTheme.levelLow;
    } else if (sugarPer100 <= highCutoff) {
      return GlucioTheme.levelMedium;
    } else {
      return GlucioTheme.levelHigh;
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
