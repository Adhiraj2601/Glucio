import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/data/models/off_product_dto.dart';
import 'package:glucio/data/models/product_details.dart';

void main() {
  group('OffProductDto Unit Tests', () {
    final sampleOffJson = {
      'code': '7622210449283',
      'product_name': 'Prince Goût Chocolat au Blé Complet',
      'brands': 'Mondelez Schweiz GmbH',
      'quantity': '300 g e',
      'serving_size': '1 biscuit (20g)',
      'image_front_url': 'https://images.openfoodfacts.org/front.jpg',
      'image_ingredients_url': 'https://images.openfoodfacts.org/ing.jpg',
      'image_nutrition_url': 'https://images.openfoodfacts.org/nutr.jpg',
      'ingredients_text':
          'Céréales 50 % (farine de blé 41 %, farine de blé complet 9 %), sucre, huile de palme, cacao maigre en poudre, sel, poudre à lever (carbonates d\'ammonium, carbonates de sodium), émulsifiant (lécithines de soja).',
      'ingredients_analysis_tags': [
        'en:palm-oil',
        'en:vegetarian-status-unknown',
        'en:non-vegan'
      ],
      'allergens_tags': ['en:gluten', 'en:soybeans'],
      'traces_tags': ['en:milk', 'en:nuts'],
      'additives_tags': ['en:e322', 'en:e500', 'en:e503'],
      'labels_tags': ['en:green-dot', 'en:pure-butter'],
      'origins': 'France',
      'packaging': 'Sachet plastique, boîte carton',
      'packaging_tags': ['en:cardboard', 'en:plastic'],
      'categories_tags': ['en:biscuits', 'en:chocolate-biscuits'],
      'nutriscore_grade': 'e',
      'nutriscore_data': {
        'negative_points': 17,
        'positive_points': 2,
        'energy_points': 5,
        'sugars_points': 9,
      },
      'nova_group': 4,
      'ecoscore_grade': 'd',
      'nutrient_levels': {
        'fat': 'moderate',
        'saturated-fat': 'high',
        'sugars': 'high',
        'salt': 'moderate',
      },
      'nutriments': {
        'energy-kcal_100g': 465.0,
        'energy-kcal_serving': 93.0,
        'fat_100g': 17.0,
        'fat_serving': 3.4,
        'saturated-fat_100g': 5.6,
        'saturated-fat_serving': 1.1,
        'carbohydrates_100g': 68.0,
        'carbohydrates_serving': 13.6,
        'sugars_100g': 32.0,
        'sugars_serving': 6.4,
        'fiber_100g': 4.3,
        'fiber_serving': 0.86,
        'proteins_100g': 6.3,
        'proteins_serving': 1.26,
        'salt_100g': 0.49,
        'salt_serving': 0.1,
      },
      'nutrition_data_per': '100g',
    };

    test('parses full OFF v2 JSON successfully', () {
      final dto = OffProductDto.fromJson(sampleOffJson);

      expect(dto.code, '7622210449283');
      expect(dto.productName, 'Prince Goût Chocolat au Blé Complet');
      expect(dto.brands, 'Mondelez Schweiz GmbH');
      expect(dto.quantity, '300 g e');
      expect(dto.nutriScoreGrade, 'e');
      expect(dto.novaGroup, 4);
      expect(dto.ecoScoreGrade, 'd');
      expect(dto.allergensTags, contains('en:gluten'));
      expect(dto.additivesTags, contains('en:e322'));
    });

    test('converts to Product and ProductDetails with strict null safety', () {
      final dto = OffProductDto.fromJson(sampleOffJson);
      final product = dto.toProduct();

      expect(product.barcode, '7622210449283');
      expect(product.sugarPer100, 32.0);
      expect(product.nutriScoreGrade, 'e');
      expect(product.novaGroup, 4);
      expect(product.ecoScoreGrade, 'd');
      expect(product.details, isNotNull);

      final details = product.details!;
      expect(details.nutrientLevels?.sugars, 'high');
      expect(details.nutrientLevels?.saturatedFat, 'high');
      expect(details.fullNutriments?.energyKcal100g, 465.0);
      expect(details.fullNutriments?.sugarsServing, 6.4);
      expect(details.ingredientsAnalysis?.palmOil, 'yes');
      expect(details.hasAdditives, isTrue);
      expect(details.additives.length, 3);
    });

    test('preserves null sugar strictly when sugars are absent from nutriments', () {
      final jsonMissingSugar = Map<String, dynamic>.from(sampleOffJson);
      final nutrimentsWithoutSugar = Map<String, dynamic>.from(sampleOffJson['nutriments'] as Map);
      nutrimentsWithoutSugar.remove('sugars_100g');
      nutrimentsWithoutSugar.remove('sugars_value');
      jsonMissingSugar['nutriments'] = nutrimentsWithoutSugar;

      final dto = OffProductDto.fromJson(jsonMissingSugar);
      final product = dto.toProduct();

      expect(product.sugarPer100, isNull);
      expect(product.hasSugarData, isFalse);
    });

    test('serializes and deserializes ProductDetails to/from JSON accurately', () {
      final dto = OffProductDto.fromJson(sampleOffJson);
      final details = dto.toProductDetails();
      final jsonMap = details.toJson();

      final restored = ProductDetails.fromJson(jsonMap);
      expect(restored.barcode, details.barcode);
      expect(restored.nutriScoreGrade, 'e');
      expect(restored.novaGroup, 4);
      expect(restored.allergenTags, contains('en:gluten'));
      expect(restored.nutrientLevels?.sugars, 'high');
      expect(restored.fullNutriments?.sugars100g, 32.0);
    });
  });
}
