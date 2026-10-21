/// Domain model representing a single food portion logged by the user.
class FoodLogEntry {
  final int? id;
  final String barcode;
  final String name;
  final String brand;
  final String portionLabel;
  final double portionAmount;
  final String portionBasis;
  final double? sugarGrams;
  final DateTime loggedAt;

  const FoodLogEntry({
    this.id,
    required this.barcode,
    required this.name,
    this.brand = '',
    required this.portionLabel,
    required this.portionAmount,
    this.portionBasis = 'g',
    this.sugarGrams,
    required this.loggedAt,
  });

  /// Approximate teaspoons calculation (1 tsp = 4.0g) if sugar is known.
  double? get teaspoons => sugarGrams != null ? sugarGrams! / 4.0 : null;

  /// Plain text teaspoons description for UI display.
  String get sugarTeaspoonsText {
    if (teaspoons == null) return 'Sugar unknown';
    return 'about ${teaspoons!.toStringAsFixed(1)} tsp';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'portion_label': portionLabel,
      'portion_amount': portionAmount,
      'portion_basis': portionBasis,
      'sugar_grams': sugarGrams,
      'logged_at': loggedAt.toIso8601String(),
    };
  }

  factory FoodLogEntry.fromMap(Map<String, dynamic> map) {
    return FoodLogEntry(
      id: map['id'] as int?,
      barcode: map['barcode'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown Product',
      brand: map['brand'] as String? ?? '',
      portionLabel: map['portion_label'] as String? ?? '1 serving',
      portionAmount: (map['portion_amount'] as num?)?.toDouble() ?? 0.0,
      portionBasis: map['portion_basis'] as String? ?? 'g',
      sugarGrams: (map['sugar_grams'] as num?)?.toDouble(),
      loggedAt: map['logged_at'] != null
          ? DateTime.tryParse(map['logged_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  FoodLogEntry copyWith({
    int? id,
    String? barcode,
    String? name,
    String? brand,
    String? portionLabel,
    double? portionAmount,
    String? portionBasis,
    double? sugarGrams,
    DateTime? loggedAt,
  }) {
    return FoodLogEntry(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      portionLabel: portionLabel ?? this.portionLabel,
      portionAmount: portionAmount ?? this.portionAmount,
      portionBasis: portionBasis ?? this.portionBasis,
      sugarGrams: sugarGrams ?? this.sugarGrams,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }
}
