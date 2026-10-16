import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Pure utility class for nutrition and sugar calculations.
///
/// Designed to keep math simple, fully testable, and transparent for educational explanation.
class SugarCalculator {
  SugarCalculator._();

  /// Converts grams of sugar into teaspoons.
  /// 1 teaspoon = 4.0 grams.
  static double toTeaspoons(double grams) {
    if (grams <= 0) return 0.0;
    return grams / AppConstants.gramsPerTeaspoon;
  }

  /// Formats teaspoon count rounded to 1 decimal place (e.g. 3.2).
  static String formatTeaspoons(double teaspoons) {
    if (teaspoons <= 0) return '0.0';
    return teaspoons.toStringAsFixed(1);
  }

  /// Converts grams of sugar into sugar cubes count (1 cube = 4.0 grams).
  static double toSugarCubes(double grams) {
    return toTeaspoons(grams);
  }

  /// Calculates the percentage of the WHO recommended daily limit (default 25g).
  static double toPercentDailyLimit(
    double grams, {
    double dailyLimitGrams = AppConstants.defaultDailySugarLimitGrams,
  }) {
    if (grams <= 0 || dailyLimitGrams <= 0) return 0.0;
    return (grams / dailyLimitGrams) * 100.0;
  }

  /// Computes the absolute sugar grams for a given portion size in grams.
  /// Formula: (sugarPer100g * portionSizeG) / 100
  static double calculatePortionSugar({
    required double sugarPer100g,
    required double portionSizeG,
  }) {
    if (sugarPer100g <= 0 || portionSizeG <= 0) return 0.0;
    return (sugarPer100g * portionSizeG) / 100.0;
  }

  /// Returns the UI color corresponding to the % of daily limit consumed.
  /// - < 50%: Green (Safe / Low)
  /// - 50% - 100%: Amber (Moderate)
  /// - > 100%: Red (High / Exceeds limit)
  static Color getSeverityColor(double percent) {
    if (percent < 50.0) {
      return AppConstants.sugarLowGreen;
    } else if (percent <= 100.0) {
      return AppConstants.sugarMediumAmber;
    } else {
      return AppConstants.sugarHighRed;
    }
  }

  /// Returns a human-friendly severity label based on percentage of daily limit.
  static String getSeverityLabel(double percent) {
    if (percent < 50.0) {
      return 'Low Sugar';
    } else if (percent <= 100.0) {
      return 'Moderate Sugar';
    } else {
      return 'High Sugar';
    }
  }

  /// Detects whether sugar is hidden in an unexpectedly savory product.
  /// Checks explicit flag first, then heuristics (category match + sugar >= 5g/100g).
  static bool isHiddenSugar({
    required String category,
    required double sugarPer100g,
    bool explicitFlag = false,
  }) {
    if (explicitFlag) return true;
    final cat = category.trim().toLowerCase();
    final isSavory = AppConstants.savoryCategories.any(
      (c) => cat.contains(c),
    );
    return isSavory && sugarPer100g >= AppConstants.hiddenSugarSavoryThresholdGrams;
  }
}
