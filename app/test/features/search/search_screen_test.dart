import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/data/models/portion.dart';
import 'package:glucio/data/models/product.dart';
import 'package:glucio/data/models/product_details.dart';
import 'package:glucio/data/repositories/product_repository.dart';
import 'package:glucio/features/search/presentation/search_screen.dart';
import 'package:http/http.dart' as http;

void main() {
  group('SearchScreen Widget Tests', () {
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
        nutriScoreGrade: 'e',
        novaGroup: 4,
        imageUrls: ProductImageUrls(),
      ),
      source: 'open-food-facts',
      verified: true,
    );

    testWidgets('renders search bar, category chips, and popular searches',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Search & Discover'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('India Only'), findsOneWidget);

      // Categories
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Biscuits'), findsOneWidget);
      expect(find.text('Beverages'), findsOneWidget);

      // Popular searches
      expect(find.text('POPULAR SEARCHES'), findsOneWidget);
      expect(find.text('Parle-G'), findsOneWidget);
      expect(find.text('Thums Up'), findsOneWidget);
    });

    testWidgets('typing search query displays matching product cards',
        (WidgetTester tester) async {
      final mockRepo = _MockOffRepository([parleG]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search term
      await tester.enterText(find.byType(TextField), 'Parle');
      // Wait for debounce timer (350ms)
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Parle-G Gluco Biscuits'), findsOneWidget);
      expect(find.text('Parle'), findsWidgets);
      expect(find.textContaining('25.5g sugar'), findsOneWidget);
      expect(find.text('NUTRI-SCORE E'), findsOneWidget);
      expect(find.text('NOVA 4'), findsOneWidget);
    });

    testWidgets('entering valid barcode shows direct lookup notice',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid EAN barcode (Parle-G real check digit: 4)
      await tester.enterText(find.byType(TextField), '8901063012134');
      await tester.pumpAndSettle();

      expect(find.textContaining('Valid Barcode: 8901063012134'), findsOneWidget);
      expect(find.textContaining('Tap to lookup directly'), findsOneWidget);
    });

    testWidgets('tapping compare button adds product to productCompareProvider',
        (WidgetTester tester) async {
      final mockRepo = _MockOffRepository([parleG]);
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: SearchScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Parle');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(container.read(productCompareProvider), isEmpty);

      // Tap compare button on search result item
      final compareBtn = find.byTooltip('Add to Compare');
      expect(compareBtn, findsOneWidget);
      await tester.tap(compareBtn);
      await tester.pumpAndSettle();

      expect(container.read(productCompareProvider).length, 1);
      expect(container.read(productCompareProvider).first.barcode, '8901063012130');
    });
  });
}

class _MockOffRepository extends OffRepository {
  final List<Product> _mockResults;
  _MockOffRepository(this._mockResults);

  @override
  Future<List<Product>> searchProducts(
    String query, {
    bool indiaOnly = true,
    String? category,
    http.Client? client,
  }) async {
    return _mockResults;
  }
}
