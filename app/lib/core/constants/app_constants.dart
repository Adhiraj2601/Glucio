import 'package:flutter/material.dart';

/// App-wide constants for nutrition math, limits, and UI theming.
class AppConstants {
  AppConstants._();

  /// Default WHO recommended free sugar daily limit in grams.
  static const double defaultDailySugarLimitGrams = 25.0;

  /// Grams of sugar in 1 standard teaspoon / 1 standard sugar cube.
  static const double gramsPerTeaspoon = 4.0;

  /// Grams of sugar in 1 sugar cube (equivalent to 1 teaspoon).
  static const double gramsPerSugarCube = 4.0;

  /// Threshold (g per 100g) for savory products to trigger a hidden sugar warning.
  static const double hiddenSugarSavoryThresholdGrams = 5.0;

  /// Color for sugar intake < 50% of daily limit.
  static const Color sugarLowGreen = Color(0xFF2E7D32);

  /// Color for sugar intake 50% - 100% of daily limit.
  static const Color sugarMediumAmber = Color(0xFFED6C02);

  /// Color for sugar intake > 100% of daily limit.
  static const Color sugarHighRed = Color(0xFFD32F2F);

  /// Savory categories where hidden sugars commonly lurk.
  static const Set<String> savoryCategories = {
    'sauces',
    'ketchup',
    'namkeen',
    'instant noodles',
    'chips',
    'bread',
    'soup',
    'savory',
  };
}
