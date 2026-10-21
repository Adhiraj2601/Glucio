import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/core/models/sugar_swap.dart';
import 'package:glucio/data/models/product.dart';
import 'package:glucio/data/repositories/product_repository.dart';
import 'package:glucio/features/product/presentation/widgets/smarter_swaps_card.dart';

void main() {
  group('SmarterSwapsCard Widget Tests', () {
    const highSugarProduct = Product(
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

    const lowerSugarSwap = Product(
      barcode: '8901063012130',
      name: 'Parle-G Original Gluco Biscuits',
      brand: 'Parle',
      category: 'biscuits',
      packSize: 250.0,
      servingSize: 25.0,
      sugarPer100: 25.5,
      sugarBasis: 'per_100g',
      portions: [],
      source: 'seed',
      verified: true,
    );

    testWidgets('renders Smarter Swaps header, swap item, and savings badge', (tester) async {
      Product? selectedSwap;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lowerSugarSwapsProvider(highSugarProduct).overrideWith(
              (ref) => [
                SugarSwap.fromProducts(
                  original: highSugarProduct,
                  swap: lowerSugarSwap,
                ),
              ],
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SmarterSwapsCard(
                  product: highSugarProduct,
                  onSelectSwap: (prod) => selectedSwap = prod,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Smarter Swaps'), findsOneWidget);
      expect(find.text('Lower Sugar'), findsOneWidget);

      // Check alternative item details
      expect(find.text('Parle-G Original Gluco Biscuits'), findsOneWidget);
      expect(find.textContaining('25.5g sugar / 100g'), findsOneWidget);
      expect(find.textContaining('Saves 12.5g'), findsOneWidget);

      // Tap swap item
      await tester.tap(find.text('Parle-G Original Gluco Biscuits'));
      await tester.pumpAndSettle();

      expect(selectedSwap?.barcode, '8901063012130');
    });

    testWidgets('displays positive badge when no lower alternatives exist', (tester) async {
      const alreadyLowProduct = Product(
        barcode: '8901234567890',
        name: 'Diet Water',
        brand: 'Generic',
        category: 'water',
        packSize: 1000.0,
        servingSize: 250.0,
        sugarPer100: 0.0,
        portions: [],
        source: 'seed',
        verified: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lowerSugarSwapsProvider(alreadyLowProduct).overrideWith(
              (ref) => [],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SmarterSwapsCard(
                  product: alreadyLowProduct,
                  onSelectSwap: _dummyCallback,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Smarter Swaps'), findsOneWidget);
      expect(find.textContaining('Great choice!'), findsOneWidget);
    });
  });
}

void _dummyCallback(Product p) {}
