import '../../data/models/product.dart';

/// Represents a lower-sugar alternative recommendation for a food product.
class SugarSwap {
  final Product originalProduct;
  final Product swapProduct;
  final double sugarSavedPer100;
  final double tspSavedPer100;
  final double percentSugarSaved;

  const SugarSwap({
    required this.originalProduct,
    required this.swapProduct,
    required this.sugarSavedPer100,
    required this.tspSavedPer100,
    required this.percentSugarSaved,
  });

  /// Factory calculating exact sugar savings between the original and alternative.
  factory SugarSwap.fromProducts({
    required Product original,
    required Product swap,
  }) {
    final origSugar = original.sugarPer100 ?? 0.0;
    final swapSugar = swap.sugarPer100 ?? 0.0;
    final savedGrams = (origSugar - swapSugar).clamp(0.0, 100.0);
    final savedTsp = savedGrams / 4.0;
    final pct = origSugar > 0 ? ((savedGrams / origSugar) * 100.0).clamp(0.0, 100.0) : 0.0;

    return SugarSwap(
      originalProduct: original,
      swapProduct: swap,
      sugarSavedPer100: savedGrams,
      tspSavedPer100: savedTsp,
      percentSugarSaved: pct,
    );
  }

  /// Formatted plain-language summary of sugar savings per 100g.
  String get savingsDescription {
    if (sugarSavedPer100 <= 0.0) return 'Comparable sugar';
    if (tspSavedPer100 < 0.5) {
      return 'Saves ${sugarSavedPer100.toStringAsFixed(1)}g sugar / 100g';
    }
    return 'Saves ${sugarSavedPer100.toStringAsFixed(1)}g (≈ ${tspSavedPer100.toStringAsFixed(1)} tsp) / 100g';
  }
}
