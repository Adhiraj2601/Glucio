import '../../core/utils/sugar_calculator.dart';

/// Product domain model representing a packaged food item with nutrition data.
class Product {
  final String barcode;
  final String name;
  final String brand;
  final String category;
  final double packSizeG;
  final double servingSizeG;
  final double sugarPer100g;
  final double? addedSugarPer100g;
  final bool hiddenSugarFlag;
  final String source;
  final bool verified;

  const Product({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.category,
    required this.packSizeG,
    required this.servingSizeG,
    required this.sugarPer100g,
    this.addedSugarPer100g,
    this.hiddenSugarFlag = false,
    required this.source,
    required this.verified,
  });

  /// Factory from JSON map (from local seed asset or API response).
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      barcode: json['barcode']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Product',
      brand: json['brand']?.toString() ?? 'Generic',
      category: json['category']?.toString() ?? 'Snacks',
      packSizeG: (json['pack_size_g'] as num?)?.toDouble() ?? 100.0,
      servingSizeG: (json['serving_size_g'] as num?)?.toDouble() ?? 30.0,
      sugarPer100g: (json['sugar_per_100g'] as num?)?.toDouble() ?? 0.0,
      addedSugarPer100g: (json['added_sugar_per_100g'] as num?)?.toDouble(),
      hiddenSugarFlag: json['hidden_sugar_flag'] == true,
      source: json['source']?.toString() ?? 'seed-unverified',
      verified: json['verified'] == true,
    );
  }

  /// Converts product to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'category': category,
      'pack_size_g': packSizeG,
      'serving_size_g': servingSizeG,
      'sugar_per_100g': sugarPer100g,
      'added_sugar_per_100g': addedSugarPer100g,
      'hidden_sugar_flag': hiddenSugarFlag,
      'source': source,
      'verified': verified,
    };
  }

  /// Total sugar in grams for one standard serving.
  double get servingSugarG => SugarCalculator.calculatePortionSugar(
        sugarPer100g: sugarPer100g,
        portionSizeG: servingSizeG,
      );

  /// Teaspoons of sugar for one serving.
  double get servingTeaspoons => SugarCalculator.toTeaspoons(servingSugarG);

  /// % of WHO daily limit (25g) for one serving.
  double get servingDailyPercent =>
      SugarCalculator.toPercentDailyLimit(servingSugarG);

  /// Total sugar in grams for the entire pack.
  double get packSugarG => SugarCalculator.calculatePortionSugar(
        sugarPer100g: sugarPer100g,
        portionSizeG: packSizeG,
      );

  /// Teaspoons of sugar for the entire pack.
  double get packTeaspoons => SugarCalculator.toTeaspoons(packSugarG);

  /// % of WHO daily limit (25g) for the entire pack.
  double get packDailyPercent => SugarCalculator.toPercentDailyLimit(packSugarG);

  /// True if product contains hidden sugar according to heuristics or explicit flag.
  bool get hasHiddenSugar => SugarCalculator.isHiddenSugar(
        category: category,
        sugarPer100g: sugarPer100g,
        explicitFlag: hiddenSugarFlag,
      );
}
