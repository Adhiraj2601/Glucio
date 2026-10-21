/// Model representing a scanned product in the chronological scan history.
class ScanHistoryEntry {
  final int? id;
  final String barcode;
  final String name;
  final String? brand;
  final String? category;
  final double? sugarPer100;
  final String? nutriScoreGrade;
  final int? novaGroup;
  final DateTime scannedAt;

  const ScanHistoryEntry({
    this.id,
    required this.barcode,
    required this.name,
    this.brand,
    this.category,
    this.sugarPer100,
    this.nutriScoreGrade,
    this.novaGroup,
    required this.scannedAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'category': category,
        'sugar_per_100': sugarPer100,
        'nutriscore_grade': nutriScoreGrade,
        'nova_group': novaGroup,
        'scanned_at': scannedAt.toIso8601String(),
      };

  factory ScanHistoryEntry.fromMap(Map<String, dynamic> map) =>
      ScanHistoryEntry(
        id: map['id'] as int?,
        barcode: map['barcode'] as String,
        name: map['name'] as String? ?? 'Scanned Food',
        brand: map['brand'] as String?,
        category: map['category'] as String?,
        sugarPer100: (map['sugar_per_100'] as num?)?.toDouble(),
        nutriScoreGrade: map['nutriscore_grade'] as String?,
        novaGroup: (map['nova_group'] as num?)?.toInt(),
        scannedAt: map['scanned_at'] != null
            ? DateTime.tryParse(map['scanned_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
