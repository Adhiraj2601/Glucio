import 'dart:convert';
import '../../core/utils/additive_risk_lookup.dart';

/// Image URLs associated with the product packaging.
class ProductImageUrls {
  final String? front;
  final String? frontSmall;
  final String? ingredients;
  final String? nutrition;

  const ProductImageUrls({
    this.front,
    this.frontSmall,
    this.ingredients,
    this.nutrition,
  });

  bool get hasAnyImage =>
      front != null || frontSmall != null || ingredients != null || nutrition != null;

  Map<String, dynamic> toJson() => {
        'front': front,
        'front_small': frontSmall,
        'ingredients': ingredients,
        'nutrition': nutrition,
      };

  factory ProductImageUrls.fromJson(Map<String, dynamic> json) =>
      ProductImageUrls(
        front: json['front'] as String?,
        frontSmall: json['front_small'] as String?,
        ingredients: json['ingredients'] as String?,
        nutrition: json['nutrition'] as String?,
      );
}

/// Nutrient level thresholds (low, moderate, high).
class NutrientLevels {
  final String? fat;
  final String? saturatedFat;
  final String? sugars;
  final String? salt;

  const NutrientLevels({
    this.fat,
    this.saturatedFat,
    this.sugars,
    this.salt,
  });

  Map<String, dynamic> toJson() => {
        'fat': fat,
        'saturated_fat': saturatedFat,
        'sugars': sugars,
        'salt': salt,
      };

  factory NutrientLevels.fromJson(Map<String, dynamic> json) => NutrientLevels(
        fat: json['fat'] as String?,
        saturatedFat: json['saturated_fat'] as String?,
        sugars: json['sugars'] as String?,
        salt: json['salt'] as String?,
      );
}

/// Full nutrient values per 100g and per serving.
class FullNutriments {
  final double? energyKcal100g;
  final double? energyKcalServing;
  final double? fat100g;
  final double? fatServing;
  final double? saturatedFat100g;
  final double? saturatedFatServing;
  final double? carbohydrates100g;
  final double? carbohydratesServing;
  final double? sugars100g;
  final double? sugarsServing;
  final double? fiber100g;
  final double? fiberServing;
  final double? proteins100g;
  final double? proteinsServing;
  final double? salt100g;
  final double? saltServing;
  final double? sodium100g;
  final double? sodiumServing;

  const FullNutriments({
    this.energyKcal100g,
    this.energyKcalServing,
    this.fat100g,
    this.fatServing,
    this.saturatedFat100g,
    this.saturatedFatServing,
    this.carbohydrates100g,
    this.carbohydratesServing,
    this.sugars100g,
    this.sugarsServing,
    this.fiber100g,
    this.fiberServing,
    this.proteins100g,
    this.proteinsServing,
    this.salt100g,
    this.saltServing,
    this.sodium100g,
    this.sodiumServing,
  });

  Map<String, dynamic> toJson() => {
        'energy_kcal_100g': energyKcal100g,
        'energy_kcal_serving': energyKcalServing,
        'fat_100g': fat100g,
        'fat_serving': fatServing,
        'saturated_fat_100g': saturatedFat100g,
        'saturated_fat_serving': saturatedFatServing,
        'carbohydrates_100g': carbohydrates100g,
        'carbohydrates_serving': carbohydratesServing,
        'sugars_100g': sugars100g,
        'sugars_serving': sugarsServing,
        'fiber_100g': fiber100g,
        'fiber_serving': fiberServing,
        'proteins_100g': proteins100g,
        'proteins_serving': proteinsServing,
        'salt_100g': salt100g,
        'salt_serving': saltServing,
        'sodium_100g': sodium100g,
        'sodium_serving': sodiumServing,
      };

  factory FullNutriments.fromJson(Map<String, dynamic> json) => FullNutriments(
        energyKcal100g: (json['energy_kcal_100g'] as num?)?.toDouble(),
        energyKcalServing: (json['energy_kcal_serving'] as num?)?.toDouble(),
        fat100g: (json['fat_100g'] as num?)?.toDouble(),
        fatServing: (json['fat_serving'] as num?)?.toDouble(),
        saturatedFat100g: (json['saturated_fat_100g'] as num?)?.toDouble(),
        saturatedFatServing: (json['saturated_fat_serving'] as num?)?.toDouble(),
        carbohydrates100g: (json['carbohydrates_100g'] as num?)?.toDouble(),
        carbohydratesServing:
            (json['carbohydrates_serving'] as num?)?.toDouble(),
        sugars100g: (json['sugars_100g'] as num?)?.toDouble(),
        sugarsServing: (json['sugars_serving'] as num?)?.toDouble(),
        fiber100g: (json['fiber_100g'] as num?)?.toDouble(),
        fiberServing: (json['fiber_serving'] as num?)?.toDouble(),
        proteins100g: (json['proteins_100g'] as num?)?.toDouble(),
        proteinsServing: (json['proteins_serving'] as num?)?.toDouble(),
        salt100g: (json['salt_100g'] as num?)?.toDouble(),
        saltServing: (json['salt_serving'] as num?)?.toDouble(),
        sodium100g: (json['sodium_100g'] as num?)?.toDouble(),
        sodiumServing: (json['sodium_serving'] as num?)?.toDouble(),
      );
}

/// Dietary and ingredient analysis tags (vegan, vegetarian, palm oil).
class IngredientsAnalysis {
  final String vegan; // 'yes', 'no', 'maybe', 'unknown'
  final String vegetarian; // 'yes', 'no', 'maybe', 'unknown'
  final String palmOil; // 'yes', 'no', 'maybe', 'unknown'

  const IngredientsAnalysis({
    this.vegan = 'unknown',
    this.vegetarian = 'unknown',
    this.palmOil = 'unknown',
  });

  Map<String, dynamic> toJson() => {
        'vegan': vegan,
        'vegetarian': vegetarian,
        'palm_oil': palmOil,
      };

  factory IngredientsAnalysis.fromJson(Map<String, dynamic> json) =>
      IngredientsAnalysis(
        vegan: json['vegan'] as String? ?? 'unknown',
        vegetarian: json['vegetarian'] as String? ?? 'unknown',
        palmOil: json['palm_oil'] as String? ?? 'unknown',
      );
}

/// Enriched product details containing Nutri-Score, NOVA, ingredients, allergens, and nutriments.
class ProductDetails {
  final String barcode;
  final String? quantity;
  final ProductImageUrls imageUrls;
  final String? ingredientsText;
  final List<String> ingredientsAnalysisTags;
  final List<String> allergenTags;
  final List<String> traceTags;
  final List<String> additiveTags;
  final List<String> labelTags;
  final String? origins;
  final String? packaging;
  final List<String> packagingTags;
  final List<String> categoriesTags;
  final String? nutriScoreGrade; // 'a', 'b', 'c', 'd', 'e'
  final Map<String, dynamic>? nutriScoreData;
  final int? novaGroup; // 1, 2, 3, 4
  final String? ecoScoreGrade; // 'a', 'b', 'c', 'd', 'e'
  final Map<String, dynamic>? ecoScoreData;
  final NutrientLevels? nutrientLevels;
  final FullNutriments? fullNutriments;
  final IngredientsAnalysis? ingredientsAnalysis;
  final String? rawOffJson;
  final DateTime? fetchedAt;

  const ProductDetails({
    required this.barcode,
    this.quantity,
    this.imageUrls = const ProductImageUrls(),
    this.ingredientsText,
    this.ingredientsAnalysisTags = const [],
    this.allergenTags = const [],
    this.traceTags = const [],
    this.additiveTags = const [],
    this.labelTags = const [],
    this.origins,
    this.packaging,
    this.packagingTags = const [],
    this.categoriesTags = const [],
    this.nutriScoreGrade,
    this.nutriScoreData,
    this.novaGroup,
    this.ecoScoreGrade,
    this.ecoScoreData,
    this.nutrientLevels,
    this.fullNutriments,
    this.ingredientsAnalysis,
    this.rawOffJson,
    this.fetchedAt,
  });

  bool get hasNutriScore =>
      nutriScoreGrade != null && nutriScoreGrade!.trim().isNotEmpty;

  bool get hasNova => novaGroup != null && novaGroup! >= 1 && novaGroup! <= 4;

  bool get hasIngredients =>
      ingredientsText != null && ingredientsText!.trim().isNotEmpty;

  bool get hasAllergens => allergenTags.isNotEmpty || traceTags.isNotEmpty;

  bool get hasAdditives => additiveTags.isNotEmpty;

  List<AdditiveInfo> get additives =>
      additiveTags.map((tag) => AdditiveRiskLookup.lookup(tag)).toList();

  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'quantity': quantity,
        'image_urls': imageUrls.toJson(),
        'ingredients_text': ingredientsText,
        'ingredients_analysis_tags': ingredientsAnalysisTags,
        'allergen_tags': allergenTags,
        'trace_tags': traceTags,
        'additive_tags': additiveTags,
        'label_tags': labelTags,
        'origins': origins,
        'packaging': packaging,
        'packaging_tags': packagingTags,
        'categories_tags': categoriesTags,
        'nutriscore_grade': nutriScoreGrade,
        if (nutriScoreData != null) 'nutriscore_data': nutriScoreData,
        'nova_group': novaGroup,
        'ecoscore_grade': ecoScoreGrade,
        if (ecoScoreData != null) 'ecoscore_data': ecoScoreData,
        if (nutrientLevels != null) 'nutrient_levels': nutrientLevels!.toJson(),
        if (fullNutriments != null) 'full_nutriments': fullNutriments!.toJson(),
        if (ingredientsAnalysis != null)
          'ingredients_analysis': ingredientsAnalysis!.toJson(),
        'raw_off_json': rawOffJson,
        'fetched_at': fetchedAt?.toIso8601String(),
      };

  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String && value.isNotEmpty) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
      }
      return [];
    }

    Map<String, dynamic>? parseMap(dynamic value) {
      if (value == null) return null;
      if (value is Map<String, dynamic>) return value;
      if (value is String && value.isNotEmpty) {
        try {
          return jsonDecode(value) as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    ProductImageUrls imgUrls = const ProductImageUrls();
    if (json['image_urls'] is Map<String, dynamic>) {
      imgUrls = ProductImageUrls.fromJson(json['image_urls'] as Map<String, dynamic>);
    } else {
      imgUrls = ProductImageUrls(
        front: json['image_front_url'] as String?,
        frontSmall: json['image_front_small_url'] as String?,
        ingredients: json['image_ingredients_url'] as String?,
        nutrition: json['image_nutrition_url'] as String?,
      );
    }

    NutrientLevels? levels;
    final levelsRaw = parseMap(json['nutrient_levels']);
    if (levelsRaw != null) {
      levels = NutrientLevels.fromJson(levelsRaw);
    }

    FullNutriments? nutriments;
    final nutrimentsRaw = parseMap(json['full_nutriments']);
    if (nutrimentsRaw != null) {
      nutriments = FullNutriments.fromJson(nutrimentsRaw);
    }

    IngredientsAnalysis? analysis;
    final analysisRaw = parseMap(json['ingredients_analysis']);
    if (analysisRaw != null) {
      analysis = IngredientsAnalysis.fromJson(analysisRaw);
    }

    DateTime? fetched;
    if (json['fetched_at'] != null) {
      if (json['fetched_at'] is int) {
        fetched = DateTime.fromMillisecondsSinceEpoch(json['fetched_at'] as int);
      } else if (json['fetched_at'] is String) {
        fetched = DateTime.tryParse(json['fetched_at'] as String);
      }
    }

    return ProductDetails(
      barcode: json['barcode']?.toString() ?? '',
      quantity: json['quantity'] as String?,
      imageUrls: imgUrls,
      ingredientsText: json['ingredients_text'] as String?,
      ingredientsAnalysisTags: parseStringList(json['ingredients_analysis_tags']),
      allergenTags: parseStringList(json['allergen_tags'] ?? json['allergens_tags']),
      traceTags: parseStringList(json['trace_tags'] ?? json['traces_tags']),
      additiveTags: parseStringList(json['additive_tags'] ?? json['additives_tags']),
      labelTags: parseStringList(json['label_tags'] ?? json['labels_tags']),
      origins: json['origins'] as String?,
      packaging: json['packaging'] as String?,
      packagingTags: parseStringList(json['packaging_tags']),
      categoriesTags: parseStringList(json['categories_tags']),
      nutriScoreGrade: json['nutriscore_grade']?.toString().toLowerCase(),
      nutriScoreData: parseMap(json['nutriscore_data']),
      novaGroup: (json['nova_group'] as num?)?.toInt(),
      ecoScoreGrade: json['ecoscore_grade']?.toString().toLowerCase(),
      ecoScoreData: parseMap(json['ecoscore_data']),
      nutrientLevels: levels,
      fullNutriments: nutriments,
      ingredientsAnalysis: analysis,
      rawOffJson: json['raw_off_json'] ?? json['raw_json'] as String?,
      fetchedAt: fetched,
    );
  }
}
