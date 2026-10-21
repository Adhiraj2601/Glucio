/// Importance levels for user dietary criteria in the spirit of Open Food Facts.
enum PreferenceImportance {
  notImportant,
  important,
  veryImportant,
  mandatory;

  String get label {
    switch (this) {
      case PreferenceImportance.notImportant:
        return 'Not important';
      case PreferenceImportance.important:
        return 'Important';
      case PreferenceImportance.veryImportant:
        return 'Very important';
      case PreferenceImportance.mandatory:
        return 'Mandatory';
    }
  }

  static PreferenceImportance fromString(String? val) {
    if (val == null) return PreferenceImportance.notImportant;
    switch (val.toLowerCase().replaceAll(' ', '_')) {
      case 'important':
        return PreferenceImportance.important;
      case 'very_important':
      case 'veryimportant':
        return PreferenceImportance.veryImportant;
      case 'mandatory':
        return PreferenceImportance.mandatory;
      case 'not_important':
      case 'notimportant':
      default:
        return PreferenceImportance.notImportant;
    }
  }
}

/// Category grouping for preference criteria.
enum PreferenceCategory {
  allergen,
  diet,
  nutrition,
  processing,
  environment;

  String get label {
    switch (this) {
      case PreferenceCategory.allergen:
        return 'Allergens';
      case PreferenceCategory.diet:
        return 'Dietary Restrictions';
      case PreferenceCategory.nutrition:
        return 'Nutritional Priorities';
      case PreferenceCategory.processing:
        return 'Food Processing & Additives';
      case PreferenceCategory.environment:
        return 'Environment & Packaging';
    }
  }

  static PreferenceCategory fromString(String? val) {
    if (val == null) return PreferenceCategory.diet;
    switch (val.toLowerCase()) {
      case 'allergen':
        return PreferenceCategory.allergen;
      case 'nutrition':
        return PreferenceCategory.nutrition;
      case 'processing':
        return PreferenceCategory.processing;
      case 'environment':
        return PreferenceCategory.environment;
      case 'diet':
      default:
        return PreferenceCategory.diet;
    }
  }
}

/// A single configurable user preference rule (e.g. "Avoid Gluten" -> Mandatory).
class PreferenceCriterion {
  final String id;
  final String label;
  final String description;
  final PreferenceCategory category;
  final PreferenceImportance importance;
  final DateTime updatedAt;

  const PreferenceCriterion({
    required this.id,
    required this.label,
    required this.description,
    required this.category,
    this.importance = PreferenceImportance.notImportant,
    required this.updatedAt,
  });

  PreferenceCriterion copyWith({
    PreferenceImportance? importance,
    DateTime? updatedAt,
  }) {
    return PreferenceCriterion(
      id: id,
      label: label,
      description: description,
      category: category,
      importance: importance ?? this.importance,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'criterion_id': id,
        'category': category.name,
        'importance': importance.name,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory PreferenceCriterion.fromMap(
    Map<String, dynamic> map, {
    String? fallbackLabel,
    String? fallbackDescription,
  }) {
    return PreferenceCriterion(
      id: map['criterion_id'] as String,
      label: fallbackLabel ?? map['criterion_id'] as String,
      description: fallbackDescription ?? '',
      category: PreferenceCategory.fromString(map['category'] as String?),
      importance: PreferenceImportance.fromString(map['importance'] as String?),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : DateTime.now(),
    );
  }
}

/// Complete collection of user preferences with default seed rules.
class UserPreferences {
  final Map<String, PreferenceCriterion> criteria;

  const UserPreferences({required this.criteria});

  PreferenceCriterion? getCriterion(String id) => criteria[id];

  PreferenceImportance getImportance(String id) =>
      criteria[id]?.importance ?? PreferenceImportance.notImportant;

  bool get hasActivePreferences =>
      criteria.values.any((c) => c.importance != PreferenceImportance.notImportant);

  List<PreferenceCriterion> get activeCriteria =>
      criteria.values.where((c) => c.importance != PreferenceImportance.notImportant).toList();

  List<PreferenceCriterion> getByCategory(PreferenceCategory cat) =>
      criteria.values.where((c) => c.category == cat).toList();

  UserPreferences copyWith({Map<String, PreferenceCriterion>? criteria}) {
    return UserPreferences(criteria: criteria ?? this.criteria);
  }

  /// Default baseline preferences with low-sugar defaulted to Important.
  factory UserPreferences.defaults() {
    final now = DateTime.now();
    final defaultList = <PreferenceCriterion>[
      // Allergens
      PreferenceCriterion(
        id: 'allergen_milk',
        label: 'Milk & Dairy',
        description: 'Contains milk, lactose, whey, casein',
        category: PreferenceCategory.allergen,
        updatedAt: now,
      ),
      PreferenceCriterion(
        id: 'allergen_gluten',
        label: 'Gluten / Wheat',
        description: 'Contains wheat, barley, rye, oats',
        category: PreferenceCategory.allergen,
        updatedAt: now,
      ),
      PreferenceCriterion(
        id: 'allergen_peanuts',
        label: 'Peanuts',
        description: 'Contains peanuts or peanut oil',
        category: PreferenceCategory.allergen,
        updatedAt: now,
      ),
      PreferenceCriterion(
        id: 'allergen_soy',
        label: 'Soybeans',
        description: 'Contains soy, soya lecithin, edamame',
        category: PreferenceCategory.allergen,
        updatedAt: now,
      ),
      PreferenceCriterion(
        id: 'allergen_tree_nuts',
        label: 'Tree Nuts',
        description: 'Almonds, cashews, walnuts, pistachios',
        category: PreferenceCategory.allergen,
        updatedAt: now,
      ),
      PreferenceCriterion(
        id: 'allergen_eggs',
        label: 'Eggs',
        description: 'Contains egg white, yolk, albumin',
        category: PreferenceCategory.allergen,
        updatedAt: now,
      ),
      PreferenceCriterion(
        id: 'allergen_fish',
        label: 'Fish & Crustaceans',
        description: 'Fish, shellfish, shrimp, prawns',
        category: PreferenceCategory.allergen,
        updatedAt: now,
      ),
      PreferenceCriterion(
        id: 'allergen_mustard',
        label: 'Mustard',
        description: 'Common in Indian sauces and pickles',
        category: PreferenceCategory.allergen,
        updatedAt: now,
      ),
      PreferenceCriterion(
        id: 'allergen_sesame',
        label: 'Sesame',
        description: 'Sesame seeds, til, tahini',
        category: PreferenceCategory.allergen,
        updatedAt: now,
      ),

      // Diet
      PreferenceCriterion(
        id: 'diet_vegetarian',
        label: 'Vegetarian',
        description: 'No meat, poultry, fish, gelatin, animal rennet',
        category: PreferenceCategory.diet,
        updatedAt: now,
      ),
      PreferenceCriterion(
        id: 'diet_vegan',
        label: 'Vegan',
        description: '100% plant-based, no animal derivatives or honey',
        category: PreferenceCategory.diet,
        updatedAt: now,
      ),
      PreferenceCriterion(
        id: 'diet_palm_oil_free',
        label: 'Palm Oil Free',
        description: 'Avoid palm oil, palm fat, palmitate',
        category: PreferenceCategory.diet,
        updatedAt: now,
      ),

      // Nutrition Priorities (Low sugar default: Important)
      PreferenceCriterion(
        id: 'nutr_low_sugar',
        label: 'Low Sugar (WHO 25g)',
        description: 'Prioritize foods with low sugar per 100g',
        category: PreferenceCategory.nutrition,
        importance: PreferenceImportance.important,
        updatedAt: now,
      ),
      PreferenceCriterion(
        id: 'nutr_low_salt',
        label: 'Low Salt / Sodium',
        description: 'Keep salt intake low for heart health',
        category: PreferenceCategory.nutrition,
        updatedAt: now,
      ),
      PreferenceCriterion(
        id: 'nutr_low_fat',
        label: 'Low Saturated Fat',
        description: 'Reduce unhealthy saturated fats',
        category: PreferenceCategory.nutrition,
        updatedAt: now,
      ),
      PreferenceCriterion(
        id: 'nutr_high_fiber',
        label: 'High Dietary Fiber',
        description: 'Promote gut health and satiety',
        category: PreferenceCategory.nutrition,
        updatedAt: now,
      ),
      PreferenceCriterion(
        id: 'nutr_high_protein',
        label: 'High Protein',
        description: 'Higher protein density',
        category: PreferenceCategory.nutrition,
        updatedAt: now,
      ),

      // Processing & Additives
      PreferenceCriterion(
        id: 'proc_avoid_ultra_processed',
        label: 'Avoid Ultra-Processed (NOVA 4)',
        description: 'Flag industrial food products with processing markers',
        category: PreferenceCategory.processing,
        updatedAt: now,
      ),
      PreferenceCriterion(
        id: 'proc_avoid_additives',
        label: 'Avoid High-Risk Additives',
        description: 'Flag synthetic dyes, artificial sweeteners, preservatives',
        category: PreferenceCategory.processing,
        updatedAt: now,
      ),

      // Environment
      PreferenceCriterion(
        id: 'env_good_ecoscore',
        label: 'Favorable Eco-Score (A / B)',
        description: 'Lower ecological and carbon footprint',
        category: PreferenceCategory.environment,
        updatedAt: now,
      ),
    ];

    return UserPreferences(
      criteria: {for (final c in defaultList) c.id: c},
    );
  }
}
