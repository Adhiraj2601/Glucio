import '../../core/utils/portion_builder.dart';
import 'portion.dart';
import 'product.dart';
import 'product_details.dart';

/// Data Transfer Object for parsing Open Food Facts API v2 product responses.
class OffProductDto {
  final String code;
  final String? productName;
  final String? brands;
  final String? quantity;
  final String? servingSize;
  final String? imageFrontUrl;
  final String? imageFrontSmallUrl;
  final String? imageIngredientsUrl;
  final String? imageNutritionUrl;
  final String? ingredientsText;
  final List<String> ingredientsAnalysisTags;
  final List<String> allergensTags;
  final List<String> tracesTags;
  final List<String> additivesTags;
  final List<String> labelsTags;
  final String? origins;
  final List<String> originsTags;
  final String? packaging;
  final List<String> packagingTags;
  final List<String> categoriesTags;
  final Map<String, dynamic> nutriments;
  final Map<String, dynamic> nutrientLevels;
  final String? nutriScoreGrade;
  final Map<String, dynamic>? nutriScoreData;
  final int? novaGroup;
  final String? ecoScoreGrade;
  final Map<String, dynamic>? ecoScoreData;
  final String? nutritionDataPer;

  const OffProductDto({
    required this.code,
    this.productName,
    this.brands,
    this.quantity,
    this.servingSize,
    this.imageFrontUrl,
    this.imageFrontSmallUrl,
    this.imageIngredientsUrl,
    this.imageNutritionUrl,
    this.ingredientsText,
    this.ingredientsAnalysisTags = const [],
    this.allergensTags = const [],
    this.tracesTags = const [],
    this.additivesTags = const [],
    this.labelsTags = const [],
    this.origins,
    this.originsTags = const [],
    this.packaging,
    this.packagingTags = const [],
    this.categoriesTags = const [],
    this.nutriments = const {},
    this.nutrientLevels = const {},
    this.nutriScoreGrade,
    this.nutriScoreData,
    this.novaGroup,
    this.ecoScoreGrade,
    this.ecoScoreData,
    this.nutritionDataPer,
  });

  factory OffProductDto.fromJson(Map<String, dynamic> json) {
    List<String> toList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    // Handles both wrapping { "product": { ... } } and direct product map
    final p = json.containsKey('product') && json['product'] is Map<String, dynamic>
        ? json['product'] as Map<String, dynamic>
        : json;

    final nutrimentsMap = p['nutriments'] is Map<String, dynamic>
        ? p['nutriments'] as Map<String, dynamic>
        : <String, dynamic>{};

    final nutrientLevelsMap = p['nutrient_levels'] is Map<String, dynamic>
        ? p['nutrient_levels'] as Map<String, dynamic>
        : <String, dynamic>{};

    int? nova;
    if (p['nova_group'] != null) {
      nova = (p['nova_group'] as num?)?.toInt();
    }

    return OffProductDto(
      code: p['code']?.toString() ?? '',
      productName: p['product_name']?.toString() ?? p['product_name_en']?.toString(),
      brands: p['brands']?.toString(),
      quantity: p['quantity']?.toString(),
      servingSize: p['serving_size']?.toString(),
      imageFrontUrl: p['image_front_url']?.toString(),
      imageFrontSmallUrl: p['image_front_small_url']?.toString(),
      imageIngredientsUrl: p['image_ingredients_url']?.toString(),
      imageNutritionUrl: p['image_nutrition_url']?.toString(),
      ingredientsText: p['ingredients_text']?.toString() ?? p['ingredients_text_en']?.toString(),
      ingredientsAnalysisTags: toList(p['ingredients_analysis_tags']),
      allergensTags: toList(p['allergens_tags']),
      tracesTags: toList(p['traces_tags']),
      additivesTags: toList(p['additives_tags']),
      labelsTags: toList(p['labels_tags']),
      origins: p['origins']?.toString(),
      originsTags: toList(p['origins_tags']),
      packaging: p['packaging']?.toString(),
      packagingTags: toList(p['packaging_tags']),
      categoriesTags: toList(p['categories_tags']),
      nutriments: nutrimentsMap,
      nutrientLevels: nutrientLevelsMap,
      nutriScoreGrade: p['nutriscore_grade']?.toString().toLowerCase(),
      nutriScoreData: p['nutriscore_data'] is Map<String, dynamic>
          ? p['nutriscore_data'] as Map<String, dynamic>
          : null,
      novaGroup: nova,
      ecoScoreGrade: p['ecoscore_grade']?.toString().toLowerCase(),
      ecoScoreData: p['ecoscore_data'] is Map<String, dynamic>
          ? p['ecoscore_data'] as Map<String, dynamic>
          : null,
      nutritionDataPer: p['nutrition_data_per']?.toString(),
    );
  }

  /// Converts DTO into core Product model while preserving strict null-safety.
  Product toProduct({List<Portion>? customPortions}) {
    // RULE: Missing or unstated sugar must NEVER default to 0
    double? sugar100;
    if (nutriments['sugars_100g'] != null && nutriments['sugars_100g'] != '') {
      sugar100 = (nutriments['sugars_100g'] as num?)?.toDouble();
    } else if (nutriments['sugars_value'] != null && nutriments['sugars_value'] != '') {
      sugar100 = (nutriments['sugars_value'] as num?)?.toDouble();
    }

    final double? addedSugar100 = (nutriments['added-sugars_100g'] as num?)?.toDouble();

    // Parse serving size
    double servingG = 30.0;
    if (servingSize != null) {
      final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(servingSize!);
      if (match != null) {
        servingG = double.tryParse(match.group(1)!) ?? 30.0;
      }
    }

    // Parse pack size
    double packG = 100.0;
    if (quantity != null) {
      final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(quantity!);
      if (match != null) {
        packG = double.tryParse(match.group(1)!) ?? 100.0;
      }
    }

    final cat = categoriesTags.isNotEmpty
        ? categoriesTags.first.replaceAll('en:', '').replaceAll('-', ' ').trim()
        : 'Snacks';

    final isLiquid = (nutritionDataPer?.toLowerCase() == '100ml') ||
        (quantity?.toLowerCase().contains('ml') ?? false) ||
        cat.toLowerCase().contains('beverage') ||
        cat.toLowerCase().contains('drink');

    final basis = isLiquid ? 'per_100ml' : 'per_100g';

    final portions = customPortions ??
        PortionBuilder.buildPortions(
          category: cat,
          packSize: packG > 0 ? packG : 100.0,
          servingSize: servingG > 0 ? servingG : 30.0,
          servingDescription: servingSize,
          basis: isLiquid ? 'ml' : 'g',
        );

    final details = toProductDetails();

    return Product(
      barcode: code,
      name: productName?.isNotEmpty == true ? productName! : 'Packaged Food',
      brand: brands?.isNotEmpty == true ? brands! : 'Generic',
      category: cat,
      packSize: packG > 0 ? packG : 100.0,
      servingSize: servingG > 0 ? servingG : 30.0,
      sugarPer100: sugar100,
      addedSugarPer100: addedSugar100,
      sugarBasis: basis,
      portions: portions,
      hiddenSugarFlag: false,
      source: 'openfoodfacts',
      verified: false,
      details: details,
    );
  }

  /// Converts DTO into extended ProductDetails domain model.
  ProductDetails toProductDetails({String? rawJson}) {
    String parseAnalysis(String key) {
      for (final tag in ingredientsAnalysisTags) {
        final t = tag.toLowerCase().replaceAll('en:', '').trim();
        if (key == 'palm-oil') {
          if (t == 'palm-oil' || t.endsWith('-yes') || t.contains('contains-palm-oil')) return 'yes';
          if (t == 'palm-oil-free' || t.endsWith('-no')) return 'no';
          if (t.contains('may-contain-palm-oil') || t.endsWith('-maybe')) return 'maybe';
        } else if (key == 'vegan') {
          if (t == 'vegan' || t.endsWith('-yes')) return 'yes';
          if (t == 'non-vegan' || t.endsWith('-no')) return 'no';
          if (t.contains('maybe-vegan') || t.endsWith('-maybe')) return 'maybe';
        } else if (key == 'vegetarian') {
          if (t == 'vegetarian' || t.endsWith('-yes')) return 'yes';
          if (t == 'non-vegetarian' || t.endsWith('-no')) return 'no';
          if (t.contains('maybe-vegetarian') || t.endsWith('-maybe')) return 'maybe';
        }
      }
      return 'unknown';
    }

    final analysis = IngredientsAnalysis(
      vegan: parseAnalysis('vegan'),
      vegetarian: parseAnalysis('vegetarian'),
      palmOil: parseAnalysis('palm-oil'),
    );

    final levels = NutrientLevels(
      fat: nutrientLevels['fat']?.toString(),
      saturatedFat: nutrientLevels['saturated-fat']?.toString(),
      sugars: nutrientLevels['sugars']?.toString(),
      salt: nutrientLevels['salt']?.toString(),
    );

    double? nVal(String key) => (nutriments[key] as num?)?.toDouble();

    final fullNutr = FullNutriments(
      energyKcal100g: nVal('energy-kcal_100g') ?? nVal('energy-kcal'),
      energyKcalServing: nVal('energy-kcal_serving'),
      fat100g: nVal('fat_100g') ?? nVal('fat_value'),
      fatServing: nVal('fat_serving'),
      saturatedFat100g: nVal('saturated-fat_100g') ?? nVal('saturated-fat_value'),
      saturatedFatServing: nVal('saturated-fat_serving'),
      carbohydrates100g: nVal('carbohydrates_100g') ?? nVal('carbohydrates_value'),
      carbohydratesServing: nVal('carbohydrates_serving'),
      sugars100g: nVal('sugars_100g') ?? nVal('sugars_value'),
      sugarsServing: nVal('sugars_serving'),
      fiber100g: nVal('fiber_100g') ?? nVal('fiber_value'),
      fiberServing: nVal('fiber_serving'),
      proteins100g: nVal('proteins_100g') ?? nVal('proteins_value'),
      proteinsServing: nVal('proteins_serving'),
      salt100g: nVal('salt_100g') ?? nVal('salt_value'),
      saltServing: nVal('salt_serving'),
      sodium100g: nVal('sodium_100g') ?? nVal('sodium_value'),
      sodiumServing: nVal('sodium_serving'),
    );

    return ProductDetails(
      barcode: code,
      quantity: quantity,
      imageUrls: ProductImageUrls(
        front: imageFrontUrl,
        frontSmall: imageFrontSmallUrl,
        ingredients: imageIngredientsUrl,
        nutrition: imageNutritionUrl,
      ),
      ingredientsText: ingredientsText,
      ingredientsAnalysisTags: ingredientsAnalysisTags,
      allergenTags: allergensTags,
      traceTags: tracesTags,
      additiveTags: additivesTags,
      labelTags: labelsTags,
      origins: origins,
      packaging: packaging,
      packagingTags: packagingTags,
      categoriesTags: categoriesTags,
      nutriScoreGrade: nutriScoreGrade,
      nutriScoreData: nutriScoreData,
      novaGroup: novaGroup,
      ecoScoreGrade: ecoScoreGrade,
      ecoScoreData: ecoScoreData,
      nutrientLevels: levels,
      fullNutriments: fullNutr,
      ingredientsAnalysis: analysis,
      rawOffJson: rawJson,
      fetchedAt: DateTime.now(),
    );
  }
}
