import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/core/theme/glucio_theme.dart';
import 'package:glucio/data/models/product_details.dart';
import 'package:glucio/features/product/presentation/widgets/eco_score_badge.dart';
import 'package:glucio/features/product/presentation/widgets/nova_badge.dart';
import 'package:glucio/features/product/presentation/widgets/nutri_score_badge.dart';
import 'package:glucio/features/product/presentation/widgets/nutrient_level_chips.dart';
import 'package:glucio/features/product/presentation/widgets/product_quality_row.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(
      theme: GlucioTheme.themeData,
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('Nutritional Quality Badges Widget Tests', () {
    testWidgets('NutriScoreBadge renders 5 segments and enlarges active grade E',
        (tester) async {
      await tester.pumpWidget(wrapWidget(
        const NutriScoreBadge(
          grade: 'e',
          nutriScoreData: {'negative_points': 15, 'positive_points': 2},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('NUTRI-SCORE'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
      expect(find.text('E'), findsOneWidget);

      // Tap badge to open explanation sheet
      await tester.tap(find.byType(NutriScoreBadge));
      await tester.pumpAndSettle();

      expect(find.text('Nutri-Score E'), findsOneWidget);
      expect(find.text('Lower nutritional quality'), findsOneWidget);
      expect(find.text('CALCULATION BREAKDOWN'), findsOneWidget);
      expect(find.text('Negative Points (Energy, Sugar, Sat-Fat, Salt)'), findsOneWidget);
    });

    testWidgets('NutriScoreBadge renders Not computed state when grade is null',
        (tester) async {
      await tester.pumpWidget(wrapWidget(const NutriScoreBadge(grade: null)));
      await tester.pumpAndSettle();

      expect(find.text('Nutri-Score: Not computed'), findsOneWidget);
    });

    testWidgets('NovaBadge renders NOVA 4 and opens sheet listing processing markers',
        (tester) async {
      await tester.pumpWidget(wrapWidget(
        const NovaBadge(
          group: 4,
          additiveTags: ['en:e322', 'en:e500'],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('FOOD PROCESSING'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('NOVA 4 (Ultra-processed)'), findsOneWidget);

      // Tap badge to open sheet
      await tester.tap(find.byType(NovaBadge));
      await tester.pumpAndSettle();

      expect(find.text('NOVA Group 4'), findsOneWidget);
      expect(find.text('MARKERS OF ULTRA-PROCESSING IDENTIFIED'), findsOneWidget);
      expect(find.text('E322: Lecithins'), findsOneWidget);
      expect(find.text('WHAT IS THE NOVA CLASSIFICATION?'), findsOneWidget);
    });

    testWidgets('NovaBadge renders Not computed when group is null',
        (tester) async {
      await tester.pumpWidget(wrapWidget(const NovaBadge(group: null)));
      await tester.pumpAndSettle();

      expect(find.text('NOVA: Not computed'), findsOneWidget);
    });

    testWidgets('NutrientLevelChips renders 4 chips and invokes callback on sugar tap',
        (tester) async {
      bool sugarTapped = false;
      await tester.pumpWidget(wrapWidget(
        NutrientLevelChips(
          levels: const NutrientLevels(
            sugars: 'high',
            salt: 'low',
            fat: 'moderate',
            saturatedFat: 'high',
          ),
          onSugarTapped: () => sugarTapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Sugar: '), findsOneWidget);
      expect(find.text('High'), findsNWidgets(2)); // Sugar & Sat Fat
      expect(find.text('Salt: '), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Fat: '), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('Sat Fat: '), findsOneWidget);

      // Tap Sugar chip
      await tester.tap(find.text('Sugar: '));
      await tester.pumpAndSettle();

      expect(sugarTapped, isTrue);
    });

    testWidgets('EcoScoreBadge renders grade C and opens explanation sheet',
        (tester) async {
      await tester.pumpWidget(wrapWidget(
        const EcoScoreBadge(grade: 'c'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('ECO-SCORE'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('Eco-Score C'), findsOneWidget);

      await tester.tap(find.byType(EcoScoreBadge));
      await tester.pumpAndSettle();

      expect(find.text('Moderate environmental impact'), findsOneWidget);
    });

    testWidgets('ProductQualityRow integrates NutriScore, NOVA and NutrientLevelChips',
        (tester) async {
      final details = ProductDetails(
        barcode: '123456',
        nutriScoreGrade: 'b',
        novaGroup: 3,
        nutrientLevels: const NutrientLevels(
          sugars: 'low',
          salt: 'low',
          fat: 'low',
          saturatedFat: 'low',
        ),
      );

      await tester.pumpWidget(wrapWidget(
        ProductQualityRow(details: details),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(NutriScoreBadge), findsOneWidget);
      expect(find.byType(NovaBadge), findsOneWidget);
      expect(find.byType(NutrientLevelChips), findsOneWidget);
    });
  });
}
