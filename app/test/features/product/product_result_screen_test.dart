import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/data/models/product.dart';
import 'package:glucio/features/product/presentation/product_result_screen.dart';
import 'package:glucio/features/product/presentation/product_not_found_screen.dart';

void main() {
  group('ProductResultScreen Widget Tests', () {
    final parleG = Product(
      barcode: '8901063012130',
      name: 'Parle-G Original Gluco Biscuits',
      brand: 'Parle',
      category: 'biscuits',
      packSizeG: 250.0,
      servingSizeG: 25.0,
      sugarPer100g: 25.5,
      addedSugarPer100g: 21.0,
      hiddenSugarFlag: false,
      source: 'seed-unverified',
      verified: false,
    );

    final ketchup = Product(
      barcode: '8901030383454',
      name: 'Kissan Fresh Tomato Ketchup',
      brand: 'Kissan',
      category: 'sauces',
      packSizeG: 500.0,
      servingSizeG: 15.0,
      sugarPer100g: 25.4,
      addedSugarPer100g: 24.0,
      hiddenSugarFlag: true,
      source: 'seed-unverified',
      verified: false,
    );

    testWidgets('renders Parle-G per serving teaspoons and toggles to whole pack',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductResultScreen(product: parleG),
        ),
      );
      await tester.pumpAndSettle();

      // Check name and brand
      expect(find.text('Parle-G Original Gluco Biscuits'), findsOneWidget);
      expect(find.text('Parle'), findsOneWidget);

      // Serving sugar = (25.5 * 25) / 100 = 6.375g -> 1.59 tsp -> rounded to 1.6 tsp
      expect(find.text('1.6'), findsOneWidget);
      expect(find.text('teaspoons'), findsOneWidget);

      // Toggle to Entire Pack (250g)
      final entirePackTab = find.text('Entire Pack (250g)');
      expect(entirePackTab, findsOneWidget);
      await tester.tap(entirePackTab);
      await tester.pumpAndSettle();

      // Pack sugar = (25.5 * 250) / 100 = 63.75g -> 15.9375 tsp -> rounded to 15.9 tsp
      expect(find.text('15.9'), findsOneWidget);
      expect(find.text('teaspoons'), findsOneWidget);
    });

    testWidgets('displays Hidden Sugar Alert card for savory ketchup with high sugar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductResultScreen(product: ketchup),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hidden Sugar Alert'), findsOneWidget);
      expect(
        find.textContaining('Hidden sugars are common in savory snacks and sauces!'),
        findsOneWidget,
      );
    });
  });

  group('ProductNotFoundScreen Widget Tests', () {
    testWidgets('renders barcode not found state with barcode number',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProductNotFoundScreen(barcode: '8909999999999'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Barcode Not Found'), findsOneWidget);
      expect(find.text('8909999999999'), findsOneWidget);
      expect(find.text('Scan Another Product'), findsOneWidget);
    });
  });
}
