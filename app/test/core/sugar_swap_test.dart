import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/core/models/sugar_swap.dart';
import 'package:glucio/data/models/product.dart';

void main() {
  group('SugarSwap Domain Model Tests', () {
    const originalOreo = Product(
      barcode: '8901725181222',
      name: 'Oreo Original Vanilla Creme Biscuits',
      brand: 'Cadbury',
      category: 'biscuits',
      packSize: 120.0,
      servingSize: 20.0,
      sugarPer100: 38.0,
      sugarBasis: 'per_100g',
      portions: [],
      source: 'seed',
      verified: true,
    );

    const swapGoodDay = Product(
      barcode: '8901063012222',
      name: 'Britannia Good Day Butter Biscuits',
      brand: 'Britannia',
      category: 'biscuits',
      packSize: 100.0,
      servingSize: 20.0,
      sugarPer100: 22.0,
      sugarBasis: 'per_100g',
      portions: [],
      source: 'seed',
      verified: true,
    );

    test('calculates sugar grams saved and teaspoons saved accurately', () {
      final swap = SugarSwap.fromProducts(
        original: originalOreo,
        swap: swapGoodDay,
      );

      // 38.0 - 22.0 = 16.0g
      expect(swap.sugarSavedPer100, 16.0);
      // 16.0g / 4.0 = 4.0 tsp
      expect(swap.tspSavedPer100, 4.0);
      // 16 / 38 * 100 = 42.1%
      expect(swap.percentSugarSaved, closeTo(42.1, 0.1));
      expect(swap.savingsDescription, contains('Saves 16.0g (≈ 4.0 tsp) / 100g'));
    });

    test('handles zero savings gracefully', () {
      final swap = SugarSwap.fromProducts(
        original: swapGoodDay,
        swap: originalOreo,
      );

      expect(swap.sugarSavedPer100, 0.0);
      expect(swap.tspSavedPer100, 0.0);
      expect(swap.savingsDescription, 'Comparable sugar');
    });

    test('handles null sugar in original product gracefully', () {
      const nullOriginal = Product(
        barcode: '89080443',
        name: 'Maggi Tomato Sauce',
        brand: 'Nestle',
        category: 'sauces',
        packSize: 500.0,
        servingSize: 15.0,
        sugarPer100: null,
        portions: [],
        source: 'seed',
        verified: false,
      );

      final swap = SugarSwap.fromProducts(
        original: nullOriginal,
        swap: swapGoodDay,
      );

      expect(swap.sugarSavedPer100, 0.0);
      expect(swap.percentSugarSaved, 0.0);
    });
  });
}
