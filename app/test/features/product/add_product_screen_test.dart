import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/features/product/presentation/add_product_screen.dart';

void main() {
  testWidgets('AddProductScreen renders all sections and initial barcode',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AddProductScreen(
            initialBarcode: '8901063012134',
            initialName: 'Parle-G Gluco Biscuits',
            initialBrand: 'Parle',
            initialCategory: 'biscuits',
            initialSugar: 25.5,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Barcode Card
    expect(find.text('Add or Correct Product'), findsOneWidget);
    expect(find.text('8901063012134'), findsOneWidget);
    expect(find.text('Valid EAN Checksum'), findsOneWidget);
    expect(find.text('OFF Contribution'), findsOneWidget);

    // Verify 3 Photo Slots
    expect(find.text('Front Pack'), findsOneWidget);
    expect(find.text('Ingredients'), findsOneWidget);
    expect(find.text('Nutrition'), findsOneWidget);

    // Verify Fields
    expect(find.text('Parle-G Gluco Biscuits'), findsOneWidget);
    expect(find.text('Parle'), findsOneWidget);
    expect(find.text('25.5'), findsOneWidget);

    // Verify Extended Nutriments
    expect(find.text('Extended Nutrition Facts (Per 100g/ml)'), findsOneWidget);

    // Verify Allergens
    expect(find.text('Allergens Declared on Pack'), findsOneWidget);
    expect(find.text('MILK'), findsOneWidget);
    expect(find.text('GLUTEN'), findsOneWidget);

    // Verify Actions
    expect(find.text('Contribute to Open Food Facts'), findsOneWidget);
    expect(find.text('Save & See Sugar Breakdown'), findsOneWidget);
  });

  testWidgets('AddProductScreen toggles allergen chips', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AddProductScreen(
            initialBarcode: '8901063012134',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final glutenFinder = find.text('GLUTEN');
    expect(glutenFinder, findsOneWidget);

    await tester.tap(glutenFinder);
    await tester.pumpAndSettle();

    final filterChip = tester.widget<FilterChip>(
      find.ancestor(of: glutenFinder, matching: find.byType(FilterChip)),
    );
    expect(filterChip.selected, isTrue);
  });

  testWidgets('AddProductScreen validates empty required fields', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AddProductScreen(
            initialBarcode: '8901063012134',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final submitBtn = find.text('Save & See Sugar Breakdown');
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(find.text('Product name is required'), findsOneWidget);
  });
}
