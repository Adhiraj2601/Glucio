import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/core/utils/product_alerts_engine.dart';
import 'package:glucio/data/models/off_product_dto.dart';
import 'package:glucio/data/models/product_alert_verdict.dart';
import 'package:glucio/data/models/user_preferences.dart';

void main() {
  group('ProductAlertsEngine Unit Tests', () {
    final sampleBiscuitDto = OffProductDto(
      code: '7622210449283',
      productName: 'Prince Biscuit',
      allergensTags: ['en:gluten', 'en:soybeans'],
      ingredientsText: 'Wheat flour, sugar, palm oil, soy lecithin.',
      ingredientsAnalysisTags: ['en:palm-oil', 'en:non-vegan', 'en:vegetarian'],
      nutrientLevels: {'sugars': 'high', 'salt': 'low', 'saturated-fat': 'high'},
      novaGroup: 4,
      additivesTags: ['en:e322', 'en:e500'],
      nutriments: {'sugars_100g': 32.0},
    );

    test('returns matches when product conforms to all active preferences', () {
      final prefs = UserPreferences.defaults(); // only low-sugar is Important by default
      // Create a low-sugar plain biscuit
      final lowSugarDto = OffProductDto(
        code: '123',
        productName: 'Low Sugar Crackers',
        allergensTags: [],
        ingredientsText: 'Whole wheat, water, pinch of salt.',
        nutrientLevels: {'sugars': 'low', 'salt': 'low'},
        nutriments: {'sugars_100g': 2.0},
      );

      final verdict = ProductAlertsEngine.evaluate(
        preferences: prefs,
        details: lowSugarDto.toProductDetails(),
      );

      expect(verdict.status, ProductAlertStatus.matches);
    });

    test('flags mandatory allergen violation with isMandatoryViolation = true', () {
      final defaults = UserPreferences.defaults();
      final glutenCriterion = defaults.getCriterion('allergen_gluten')!.copyWith(
            importance: PreferenceImportance.mandatory,
          );
      final prefs = defaults.copyWith(
        criteria: {...defaults.criteria, 'allergen_gluten': glutenCriterion},
      );

      final verdict = ProductAlertsEngine.evaluate(
        preferences: prefs,
        details: sampleBiscuitDto.toProductDetails(),
      );

      expect(verdict.status, ProductAlertStatus.violates);
      expect(verdict.isMandatoryViolation, isTrue);
      expect(verdict.violations.first, contains('Gluten'));
    });

    test('flags dietary restriction violations (e.g. palm oil)', () {
      final defaults = UserPreferences.defaults();
      final palmOilCriterion = defaults.getCriterion('diet_palm_oil_free')!.copyWith(
            importance: PreferenceImportance.important,
          );
      final prefs = defaults.copyWith(
        criteria: {...defaults.criteria, 'diet_palm_oil_free': palmOilCriterion},
      );

      final verdict = ProductAlertsEngine.evaluate(
        preferences: prefs,
        details: sampleBiscuitDto.toProductDetails(),
      );

      expect(verdict.status, ProductAlertStatus.violates);
      expect(verdict.violations, contains('Contains Palm Oil'));
    });

    test('flags high sugar violation when low sugar preference is active', () {
      final prefs = UserPreferences.defaults(); // Low sugar is Important
      final verdict = ProductAlertsEngine.evaluate(
        preferences: prefs,
        details: sampleBiscuitDto.toProductDetails(),
      );

      expect(verdict.status, ProductAlertStatus.violates);
      expect(verdict.violations.any((v) => v.contains('High Sugar')), isTrue);
    });

    test('returns unknown verdict when mandatory allergen cannot be verified', () {
      final defaults = UserPreferences.defaults();
      final peanutsCriterion = defaults.getCriterion('allergen_peanuts')!.copyWith(
            importance: PreferenceImportance.mandatory,
          );
      final prefs = defaults.copyWith(
        criteria: {...defaults.criteria, 'allergen_peanuts': peanutsCriterion},
      );

      // Product with no ingredients text and no allergen tags
      final emptyDto = OffProductDto(code: '999', productName: 'Mystery Item');

      final verdict = ProductAlertsEngine.evaluate(
        preferences: prefs,
        details: emptyDto.toProductDetails(),
      );

      expect(verdict.status, ProductAlertStatus.unknown);
      expect(verdict.unknownCriteria.any((u) => u.contains('Peanuts')), isTrue);
    });
  });
}
