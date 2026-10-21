import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/core/models/sugar_swap.dart';
import 'package:glucio/data/models/portion.dart';
import 'package:glucio/data/models/product.dart';
import 'package:glucio/data/models/product_alert_verdict.dart';
import 'package:glucio/data/models/product_details.dart';
import 'package:glucio/data/repositories/product_repository.dart';
import 'package:glucio/features/product/presentation/product_result_screen.dart';

void main() {
  group('ProductResultScreen Extended OFF Parity Tests', () {
    final enrichedDetails = ProductDetails(
      barcode: '8901063012130',
      quantity: '250 g',
      imageUrls: const ProductImageUrls(
        front: 'https://images.openfoodfacts.org/images/products/front.jpg',
        frontSmall: 'https://images.openfoodfacts.org/images/products/front_small.jpg',
      ),
      ingredientsText:
          'Wheat flour, sugar, edible vegetable oil, invert sugar syrup, leavening agents (INS 500ii, INS 503ii), milk solids, salt.',
      ingredientsAnalysisTags: ['en:vegetarian'],
      allergenTags: ['en:gluten', 'en:milk'],
      traceTags: ['en:soybeans'],
      additiveTags: ['en:e500ii', 'en:e503ii'],
      labelTags: ['en:vegetarian', 'en:fssai'],
      origins: 'Mumbai, India',
      packaging: 'Plastic wrapper',
      packagingTags: ['en:plastic-wrapper'],
      categoriesTags: ['en:biscuits'],
      nutriScoreGrade: 'e',
      nutriScoreData: {'score': 22},
      novaGroup: 4,
      ecoScoreGrade: 'c',
      nutrientLevels: const NutrientLevels(
        fat: 'moderate',
        saturatedFat: 'moderate',
        sugars: 'high',
        salt: 'low',
      ),
      fullNutriments: const FullNutriments(
        energyKcal100g: 450,
        fat100g: 13,
        saturatedFat100g: 6,
        carbohydrates100g: 78,
        sugars100g: 25.5,
        fiber100g: 2.5,
        proteins100g: 6.5,
        salt100g: 0.3,
      ),
      ingredientsAnalysis: const IngredientsAnalysis(
        vegetarian: 'yes',
        vegan: 'no',
        palmOil: 'no',
      ),
    );

    final enrichedProduct = Product(
      barcode: '8901063012130',
      name: 'Parle-G Original Gluco Biscuits',
      brand: 'Parle',
      category: 'biscuits',
      packSize: 250.0,
      servingSize: 25.0,
      sugarPer100: 25.5,
      sugarBasis: 'per_100g',
      portions: const [
        Portion(label: '1 biscuit', amount: 5.0, basis: 'g', kind: 'unit', source: 'label'),
      ],
      details: enrichedDetails,
      source: 'open-food-facts',
      verified: true,
    );

    testWidgets('renders Nutri-Score, NOVA, and all OFF Neo accordion cards',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lowerSugarSwapsProvider.overrideWith((ref, p) async => <SugarSwap>[]),
            productDetailsProvider('8901063012130')
                .overrideWith((ref) async => enrichedDetails),
            productAlertsProvider('8901063012130')
                .overrideWith((ref) async => ProductAlertVerdict.matches(summary: 'Preferences match')),
          ],
          child: MaterialApp(
            home: ProductResultScreen(product: enrichedProduct),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Quality Row is rendered
      expect(find.text('NUTRI-SCORE'), findsOneWidget);
      expect(find.text('E'), findsWidgets);
      expect(find.textContaining('NOVA 4'), findsOneWidget);

      // Check Nutrient Level chips
      expect(find.text('Sugar: '), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Salt: '), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);

      // Verify Neo Accordion cards exist
      expect(find.text('Ingredients & Diet'), findsOneWidget);
      expect(find.text('Allergens & Traces'), findsOneWidget);
      expect(find.text('Full Nutrition Facts'), findsOneWidget);
      expect(find.text('Additives & Processing'), findsOneWidget);
      expect(find.text('Labels & Origins'), findsOneWidget);
      expect(find.text('Packaging & Recycling'), findsOneWidget);
      expect(find.text('Technical Label Details'), findsOneWidget);

      // Expand Allergens card and verify allergen chips
      await tester.tap(find.text('Allergens & Traces'));
      await tester.pumpAndSettle();

      expect(find.text('CONTAINS ALLERGENS:'), findsOneWidget);
      expect(find.text('Gluten'), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('MAY CONTAIN TRACES OF:'), findsOneWidget);
      expect(find.text('Soybeans'), findsOneWidget);

      // Expand Additives card and verify E-number rows
      await tester.tap(find.text('Additives & Processing'));
      await tester.pumpAndSettle();

      expect(find.text('E500II'), findsWidgets);
      expect(find.text('E503II'), findsWidgets);

      // Verify OFF Community Contribution & Attribution Footer
      expect(find.text('Help Improve Glucio'), findsOneWidget);
      expect(find.text('Data from Open Food Facts, ODbL; images CC-BY-SA'), findsOneWidget);
    });

    testWidgets('displays red NOT FOR YOU banner when mandatory allergen is violated',
        (WidgetTester tester) async {
      final mandatoryViolationVerdict = ProductAlertVerdict.violates(
        reason: 'Contains Milk',
        violations: ['Contains Milk (Mandatory restriction)'],
        isMandatory: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lowerSugarSwapsProvider.overrideWith((ref, p) async => <SugarSwap>[]),
            productDetailsProvider('8901063012130')
                .overrideWith((ref) async => enrichedDetails),
            productAlertsProvider('8901063012130')
                .overrideWith((ref) async => mandatoryViolationVerdict),
          ],
          child: MaterialApp(
            home: ProductResultScreen(product: enrichedProduct),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NOT FOR YOU'), findsOneWidget);
      expect(find.textContaining('Contains Milk'), findsOneWidget);
    });

    testWidgets('tapping compare button adds product to productCompareProvider',
        (WidgetTester tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lowerSugarSwapsProvider.overrideWith((ref, p) async => <SugarSwap>[]),
            productDetailsProvider('8901063012130')
                .overrideWith((ref) async => enrichedDetails),
            productAlertsProvider('8901063012130')
                .overrideWith((ref) async => ProductAlertVerdict.matches(summary: 'OK')),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return MaterialApp(
                home: ProductResultScreen(product: enrichedProduct),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially compare list is empty
      expect(container.read(productCompareProvider), isEmpty);

      // Tap compare icon button in AppBar
      final compareBtn = find.byTooltip('Add to Compare');
      expect(compareBtn, findsOneWidget);
      await tester.tap(compareBtn);
      await tester.pumpAndSettle();

      // Now productCompareProvider contains the product
      expect(container.read(productCompareProvider).length, 1);
      expect(container.read(productCompareProvider).first.barcode, '8901063012130');
    });
  });
}
