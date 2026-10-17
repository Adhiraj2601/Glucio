import '../../core/utils/portion_builder.dart';
import '../../core/utils/sugar_calculator.dart';
import 'portion.dart';

/// Product domain model representing a packaged food item with nutrition data and household portions.
class Product {
  final String barcode;
  final String name;
  final String brand;
  final String category;
  final double packSize;
  final double servingSize;
  final double? sugarPer100;
  final double? addedSugarPer100;
  final String sugarBasis; // 'per_100g' or 'per_100ml'
  final List<Portion> portions;
  final bool hiddenSugarFlag;
  final String source;
  final bool verified;

  const Product({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.category,
    required this.packSize,
    required this.servingSize,
    this.sugarPer100,
    this.addedSugarPer100,
    this.sugarBasis = 'per_100g',
    required this.portions,
    this.hiddenSugarFlag = false,
    required this.source,
    required this.verified,
  });

  /// Factory from JSON map (local seed asset, local SQLite, or API response).
  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse portions list if present
    List<Portion> parsedPortions = [];
    if (json['portions'] != null) {
      if (json['portions'] is List) {
        parsedPortions = (json['portions'] as List)
            .map((item) => Portion.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (json['portions'] is String) {
        final entries = (json['portions'] as String).split('|');
        for (final entry in entries) {
          final p = Portion.parseSimple(entry);
          if (p != null) parsedPortions.add(p);
        }
      }
    }

    final double packG = (json['pack_size_g'] as num?)?.toDouble() ??
        (json['pack_size'] as num?)?.toDouble() ??
        100.0;
    final double servG = (json['serving_size_g'] as num?)?.toDouble() ??
        (json['serving_size'] as num?)?.toDouble() ??
        30.0;
    final String basis = json['sugar_basis']?.toString() ?? 'per_100g';
    final String cat = json['category']?.toString() ?? 'Snacks';

    // If portions list is empty or minimal, build standard portions using PortionBuilder
    if (parsedPortions.isEmpty) {
      parsedPortions = PortionBuilder.buildPortions(
        category: cat,
        packSize: packG,
        servingSize: servG,
        basis: basis == 'per_100ml' ? 'ml' : 'g',
      );
    }

    // Explicit null check: sugar_per_100g is null if missing or empty, NEVER defaulted to 0
    double? sugar100;
    if (json['sugar_per_100g'] != null && json['sugar_per_100g'] != '') {
      sugar100 = (json['sugar_per_100g'] as num?)?.toDouble();
    } else if (json['sugar_per_100'] != null && json['sugar_per_100'] != '') {
      sugar100 = (json['sugar_per_100'] as num?)?.toDouble();
    }

    return Product(
      barcode: json['barcode']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Product',
      brand: json['brand']?.toString() ?? 'Generic',
      category: cat,
      packSize: packG,
      servingSize: servG,
      sugarPer100: sugar100,
      addedSugarPer100: (json['added_sugar_per_100g'] as num?)?.toDouble() ??
          (json['added_sugar_per_100'] as num?)?.toDouble(),
      sugarBasis: basis,
      portions: parsedPortions,
      hiddenSugarFlag: json['hidden_sugar_flag'] == true,
      source: json['source']?.toString() ?? 'seed-unverified',
      verified: json['verified'] == true,
    );
  }

  /// Converts product to JSON map for local SQLite storage or export.
  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'category': category,
      'pack_size': packSize,
      'serving_size': servingSize,
      'sugar_per_100': sugarPer100,
      'added_sugar_per_100': addedSugarPer100,
      'sugar_basis': sugarBasis,
      'portions': portions.map((p) => p.toJson()).toList(),
      'hidden_sugar_flag': hiddenSugarFlag ? 1 : 0,
      'source': source,
      'verified': verified ? 1 : 0,
    };
  }

  /// True if nutrition data includes sugar.
  bool get hasSugarData => sugarPer100 != null;

  /// True ONLY when sugar is explicitly 0 and verified or label-checked.
  bool get isVerifiedZero =>
      sugarPer100 == 0.0 && (verified || source == 'label-checked');

  /// Default portion to select: smallest natural unit or label serving.
  Portion get defaultPortion {
    if (portions.isEmpty) {
      return Portion(
        label: '1 serving (${servingSize.toStringAsFixed(0)}g)',
        amount: servingSize,
        basis: sugarBasis == 'per_100ml' ? 'ml' : 'g',
        kind: 'serving',
        source: 'label',
      );
    }
    // Prefer unit or spoon or serving over whole pack
    return portions.firstWhere(
      (p) => p.kind != 'pack',
      orElse: () => portions.first,
    );
  }

  /// True if product contains hidden sugar according to heuristics or explicit flag.
  bool get hasHiddenSugar => SugarCalculator.isHiddenSugar(
        category: category,
        sugarPer100: sugarPer100,
        explicitFlag: hiddenSugarFlag,
      );

  // Backward-compatibility getters
  double get packSizeG => packSize;
  double get servingSizeG => servingSize;
  double get sugarPer100g => sugarPer100 ?? 0.0;
  double? get addedSugarPer100g => addedSugarPer100;
  double get servingSugarG => ((sugarPer100 ?? 0.0) * servingSize) / 100.0;
  double get packSugarG => ((sugarPer100 ?? 0.0) * packSize) / 100.0;
  double get servingTeaspoons => servingSugarG / 4.0;
  double get packTeaspoons => packSugarG / 4.0;
  double get servingDailyPercent => (servingSugarG / 25.0) * 100.0;
  double get packDailyPercent => (packSugarG / 25.0) * 100.0;
}
