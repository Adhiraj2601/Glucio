import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/core/models/sugar_swap.dart';
import 'package:glucio/data/models/portion.dart';
import 'package:glucio/data/models/product.dart';
import 'package:glucio/data/repositories/product_repository.dart';
import 'package:glucio/features/product/presentation/product_not_found_screen.dart';
import 'package:glucio/features/product/presentation/product_result_screen.dart';

void main() {
  group('ProductResultScreen Widget Tests', () {
    final parleG = Product(
      barcode: '8901063012130',
      name: 'Parle-G Original Gluco Biscuits',
      brand: 'Parle',
      category: 'biscuits',
      packSize: 250.0,
      servingSize: 25.0,
      sugarPer100: 25.5,
      addedSugarPer100: 21.0,
      sugarBasis: 'per_100g',
      portions: const [
        Portion(label: '1 biscuit', amount: 5.0, basis: 'g', kind: 'unit', source: 'label'),
        Portion(label: '1 serving (25g)', amount: 25.0, basis: 'g', kind: 'serving', source: 'label'),
        Portion(label: 'Whole pack (250g)', amount: 250.0, basis: 'g', kind: 'pack', source: 'label'),
      ],
      hiddenSugarFlag: false,
      source: 'seed-verified',
      verified: true,
    );

    final ketchup = Product(
      barcode: '8901030383454',
      name: 'Kissan Fresh Tomato Ketchup',
      brand: 'Kissan',
      category: 'sauces',
      packSize: 500.0,
      servingSize: 15.0,
      sugarPer100: 25.4,
      addedSugarPer100: 24.0,
      sugarBasis: 'per_100g',
      portions: const [
        Portion(label: '1 tbsp', amount: 15.0, basis: 'g', kind: 'spoon', source: 'estimate'),
        Portion(label: 'Whole pack (500g)', amount: 500.0, basis: 'g', kind: 'pack', source: 'label'),
      ],
      hiddenSugarFlag: true,
      source: 'seed-verified',
      verified: true,
    );

    final missingSugarProduct = Product(
      barcode: '89080443',
      name: 'Maggi Rich Tomato Sauce',
      brand: 'Maggi',
      category: 'sauces',
      packSize: 200.0,
      servingSize: 15.0,
      sugarPer100: null, // NULL SUGAR
      sugarBasis: 'per_100g',
      portions: const [
        Portion(label: '1 tbsp', amount: 15.0, basis: 'g', kind: 'spoon', source: 'estimate'),
      ],
      hiddenSugarFlag: false,
      source: 'open-food-facts',
      verified: false,
    );

    final zeroSugarProduct = Product(
      barcode: '8901234567890',
      name: 'Himalayan Natural Mineral Water',
      brand: 'Himalayan',
      category: 'water',
      packSize: 1000.0,
      servingSize: 250.0,
      sugarPer100: 0.0,
      sugarBasis: 'per_100ml',
      portions: const [
        Portion(label: '1 glass (250ml)', amount: 250.0, basis: 'ml', kind: 'glass', source: 'label'),
      ],
      hiddenSugarFlag: false,
      source: 'label-checked',
      verified: true,
    );

    Widget buildTestScreen(Product product) {
      return ProviderScope(
        overrides: [
          lowerSugarSwapsProvider.overrideWith((ref, p) async => <SugarSwap>[]),
        ],
        child: MaterialApp(
          home: ProductResultScreen(product: product),
        ),
      );
    }

    testWidgets('renders Parle-G with sentence hero, portion chips, and cubes',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestScreen(parleG));
      await tester.pumpAndSettle();

      // Check name and brand
      expect(find.text('Parle-G Original Gluco Biscuits'), findsOneWidget);
      expect(find.text('Parle'), findsNWidgets(2));

      // Hero sentence contains portion and sugar phrase
      expect(find.textContaining('has about'), findsOneWidget);

      // Portion chips exist
      expect(find.text('1 biscuit'), findsOneWidget);
      expect(find.text('1 serving (25g)'), findsOneWidget);
      expect(find.text('Whole pack (250g)'), findsOneWidget);

      // Multiplier buttons exist
      expect(find.text('x1'), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);
      expect(find.text('x3'), findsOneWidget);
    });

    testWidgets('displays Hidden Sugar Alert card for savory ketchup with high sugar',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestScreen(ketchup));
      await tester.pumpAndSettle();

      expect(find.text('HIDDEN SUGAR ALERT'), findsOneWidget);
      expect(
        find.textContaining('Hidden sugars are common in savory snacks and sauces!'),
        findsOneWidget,
      );
    });

    testWidgets('displays Sugar data missing state with Add or correct button when sugar is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestScreen(missingSugarProduct));
      await tester.pumpAndSettle();

      expect(find.text('Sugar data missing'), findsOneWidget);
      expect(find.text('Add or correct this product'), findsOneWidget);
      // Ensure no sugar cubes or progress bar are displayed
      expect(find.text('1 Cube = 1 Teaspoon = 4.0g sugar'), findsNothing);
      expect(find.text('WHO Daily Limit (25g)'), findsNothing);
    });

    testWidgets('displays verified zero sugar product with no sugar sentence',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestScreen(zeroSugarProduct));
      await tester.pumpAndSettle();

      expect(find.textContaining('has no sugar'), findsOneWidget);
    });
  });

  group('ProductNotFoundScreen Widget Tests', () {
    testWidgets('renders barcode not found with Add This Product button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProductNotFoundScreen(barcode: '8909999999999'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Barcode Not Found'), findsOneWidget);
      expect(find.text('8909999999999'), findsOneWidget);
      expect(find.text('Add This Product'), findsOneWidget);
      expect(find.text('Scan Another Barcode'), findsOneWidget);
    });
  });
}
