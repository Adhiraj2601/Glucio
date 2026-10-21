import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/data/models/portion.dart';
import 'package:glucio/data/models/product.dart';
import 'package:glucio/data/models/product_details.dart';
import 'package:glucio/data/repositories/product_repository.dart';
import 'package:glucio/features/compare/presentation/compare_screen.dart';

void main() {
  group('CompareScreen Widget & Ranking Tests', () {
    final parleG = Product(
      barcode: '8901063012130',
      name: 'Parle-G Gluco Biscuits',
      brand: 'Parle',
      category: 'biscuits',
      packSize: 250.0,
      servingSize: 25.0,
      sugarPer100: 25.5,
      sugarBasis: 'per_100g',
      portions: const [
        Portion(label: '1 biscuit', amount: 5.0, basis: 'g', kind: 'unit', source: 'label'),
      ],
      details: const ProductDetails(
        barcode: '8901063012130',
        quantity: '250 g',
        imageUrls: ProductImageUrls(front: 'https://images.openfoodfacts.org/front.jpg'),
        nutriScoreGrade: 'e',
        novaGroup: 4,
        additiveTags: ['en:e500ii', 'en:e503ii'],
        fullNutriments: FullNutriments(
          energyKcal100g: 450,
          fat100g: 13,
          saturatedFat100g: 6,
          carbohydrates100g: 78,
          sugars100g: 25.5,
          salt100g: 0.3,
        ),
      ),
      source: 'open-food-facts',
      verified: true,
    );

    final haldiram = Product(
      barcode: '8901725181222',
      name: "Haldiram's Alu Bhujia",
      brand: 'Haldiram',
      category: 'snacks',
      packSize: 150.0,
      servingSize: 30.0,
      sugarPer100: 2.1,
      sugarBasis: 'per_100g',
      portions: const [
        Portion(label: '1 serving (30g)', amount: 30.0, basis: 'g', kind: 'serving', source: 'label'),
      ],
      details: const ProductDetails(
        barcode: '8901725181222',
        quantity: '150 g',
        imageUrls: ProductImageUrls(),
        nutriScoreGrade: 'c',
        novaGroup: 3,
        fullNutriments: FullNutriments(
          energyKcal100g: 580,
          fat100g: 42,
          saturatedFat100g: 18,
          carbohydrates100g: 44,
          sugars100g: 2.1,
          salt100g: 1.2,
        ),
      ),
      source: 'open-food-facts',
      verified: true,
    );

    testWidgets('renders empty state when no products in comparison',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CompareScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Foods to Compare'), findsOneWidget);
      expect(find.text('Scan Food to Add'), findsOneWidget);
    });

    testWidgets('renders side-by-side comparison table with sugar hero highlight and metrics',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productCompareProvider.overrideWith(() => _MockProductCompareNotifier([parleG, haldiram])),
          ],
          child: const MaterialApp(
            home: CompareScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header bar
      expect(find.text('Compare Foods'), findsOneWidget);
      expect(find.text('2/4'), findsOneWidget);

      // In default sugar sort: Haldiram (2.1g) is #1, Parle-G (25.5g) is #2
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('Parle-G Gluco Biscuits'), findsOneWidget);
      expect(find.text("Haldiram's Alu Bhujia"), findsOneWidget);

      // Best/worst sugar highlights
      expect(find.text('Lowest Sugar'), findsWidgets);
      expect(find.text('Highest Sugar'), findsOneWidget);

      // Metric rows
      expect(find.text('SUGAR (HERO)'), findsNWidgets(2));
      expect(find.text('2.1g / 100g'), findsOneWidget);
      expect(find.text('25.5g / 100g'), findsOneWidget);
      expect(find.text('Nutri-Score'), findsNWidgets(2));
      expect(find.text('NOVA Group'), findsNWidgets(2));
      expect(find.text('Calories'), findsNWidgets(2));
      expect(find.text('Salt'), findsNWidgets(2));
    });

    testWidgets('removes product from compare when close X is tapped',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final notifier = _MockProductCompareNotifier([parleG, haldiram]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productCompareProvider.overrideWith(() => notifier),
          ],
          child: const MaterialApp(
            home: CompareScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(notifier.state.length, 2);

      // Tap first close icon
      final closeButtons = find.byIcon(Icons.close_rounded);
      expect(closeButtons, findsNWidgets(2));
      await tester.tap(closeButtons.first);
      await tester.pumpAndSettle();

      expect(notifier.state.length, 1);
    });

    testWidgets('clears all products when clear button is tapped',
        (WidgetTester tester) async {
      final notifier = _MockProductCompareNotifier([parleG, haldiram]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productCompareProvider.overrideWith(() => notifier),
          ],
          child: const MaterialApp(
            home: CompareScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final clearBtn = find.byTooltip('Clear All');
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      expect(notifier.state, isEmpty);
      expect(find.text('No Foods to Compare'), findsOneWidget);
    });
  });
}

class _MockProductCompareNotifier extends ProductCompareNotifier {
  final List<Product> _initial;
  _MockProductCompareNotifier(this._initial);

  @override
  List<Product> build() => _initial;
}
