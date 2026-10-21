/// Model representing a user-curated product list (e.g. "Favorites", "To Avoid").
class ProductList {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<String> barcodes;

  const ProductList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.barcodes = const [],
  });

  ProductList copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<String>? barcodes,
  }) {
    return ProductList(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      barcodes: barcodes ?? this.barcodes,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt.toIso8601String(),
      };

  factory ProductList.fromMap(
    Map<String, dynamic> map, {
    List<String> barcodes = const [],
  }) =>
      ProductList(
        id: map['id'] as String,
        name: map['name'] as String,
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
        barcodes: barcodes,
      );
}
