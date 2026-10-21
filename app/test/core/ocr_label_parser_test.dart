import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/core/utils/nutrition_label_ocr_parser.dart';

void main() {
  group('NutritionLabelOcrParser Regex & Extraction Tests', () {
    test('parses standard Indian biscuit label (Parle-G style)', () {
      const rawOcr = '''
      NUTRITIONAL INFORMATION
      Typical values per 100 g of product
      Energy (kcal): 454
      Carbohydrate (g): 78.2
      Total Sugars (g): 25.5
      Added Sugars (g): 21.0
      Protein (g): 6.5
      Fat (g): 13.0
      Serving Size: 25g
      ''';

      final result = NutritionLabelOcrParser.parseText(rawOcr);

      expect(result.sugarPer100, 25.5);
      expect(result.addedSugarPer100, 21.0);
      expect(result.carbohydratesPer100, 78.2);
      expect(result.energyKcal, 454.0);
      expect(result.servingSize, 25.0);
      expect(result.sugarBasis, 'per_100g');
      expect(result.hasSugar, isTrue);
    });

    test('parses beverage label with decimal commas (e.g. 10,6 g sugar)', () {
      const rawOcr = '''
      NUTRITION FACTS
      Per 100 ml
      Energy 43 kcal
      Carbohydrate 10,6 g
      Total Sugars 10,6 g
      Added Sugars 10,6 g
      Protein 0 g
      Fat 0 g
      ''';

      final result = NutritionLabelOcrParser.parseText(rawOcr);

      expect(result.sugarPer100, 10.6);
      expect(result.addedSugarPer100, 10.6);
      expect(result.carbohydratesPer100, 10.6);
      expect(result.energyKcal, 43.0);
    });

    test('parses multi-line tabular format where number is on subsequent line', () {
      const rawOcr = '''
      Nutrition Information
      Per 100g
      Energy (kcal)
      540
      Total Carbohydrate (g)
      60.0
      Total Sugars
      38.0
      Added Sugars
      35.0
      ''';

      final result = NutritionLabelOcrParser.parseText(rawOcr);

      expect(result.energyKcal, 540.0);
      expect(result.carbohydratesPer100, 60.0);
      expect(result.sugarPer100, 38.0);
      expect(result.addedSugarPer100, 35.0);
    });

    test('extracts servings per pack and serving size', () {
      const rawOcr = '''
      Serving Size: 15 g
      Servings Per Pack: 10
      Total Sugars: 3.2 g
      ''';

      final result = NutritionLabelOcrParser.parseText(rawOcr);

      expect(result.servingSize, 15.0);
      expect(result.servingsPerPack, 10);
      expect(result.sugarPer100, 3.2);
    });

    test('handles empty or unrecognized label gracefully without crashing', () {
      const emptyOcr = 'JUST INGREDIENTS LIST: Wheat flour, palm oil, salt, yeast.';

      final result = NutritionLabelOcrParser.parseText(emptyOcr);

      expect(result.sugarPer100, isNull);
      expect(result.hasSugar, isFalse);
      expect(result.isEmpty, isTrue);
    });
  });
}
