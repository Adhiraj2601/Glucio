import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';

/// Repository responsible for barcode lookups across local seed and Open Food Facts.
class ProductRepository {
  final http.Client _client;
  final Map<String, Product> _memoryCache = {};
  bool _seedLoaded = false;

  ProductRepository({http.Client? client}) : _client = client ?? http.Client();

  /// Loads bundled seed products from assets/seed_products.json.
  Future<void> loadSeedProducts() async {
    if (_seedLoaded) return;
    try {
      final jsonString =
          await rootBundle.loadString('assets/seed_products.json');
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      for (final item in list) {
        final product = Product.fromJson(item as Map<String, dynamic>);
        _memoryCache[product.barcode] = product;
      }
      _seedLoaded = true;
      debugPrint('Loaded ${_memoryCache.length} seed products into memory cache.');
    } catch (e, stack) {
      debugPrint('Error loading seed products: $e\n$stack');
    }
  }

  /// Looks up a product by barcode.
  /// Pipeline:
  /// 1. In-memory cache & seed products
  /// 2. Open Food Facts v2 API lookup
  Future<Product?> getProductByBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return null;

    // Ensure seed products are loaded
    if (!_seedLoaded) {
      await loadSeedProducts();
    }

    // 1. Check local cache (includes all seed products)
    if (_memoryCache.containsKey(cleanBarcode)) {
      return _memoryCache[cleanBarcode];
    }

    // 2. Query Open Food Facts v2 API
    try {
      final url = Uri.parse(
          'https://world.openfoodfacts.org/api/v2/product/$cleanBarcode.json');
      final response = await _client.get(
        url,
        headers: {
          'User-Agent': 'Glucio - Android - Version 1.0 (Student Project)',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 1 && data['product'] != null) {
          final p = _parseOpenFoodFacts(cleanBarcode, data['product'] as Map<String, dynamic>);
          _memoryCache[cleanBarcode] = p;
          return p;
        }
      }
    } catch (e) {
      debugPrint('Open Food Facts lookup failed: $e');
    }

    return null;
  }

  /// Parses Open Food Facts raw product JSON into our domain Product model.
  Product _parseOpenFoodFacts(String barcode, Map<String, dynamic> raw) {
    final nutriments = raw['nutriments'] as Map<String, dynamic>? ?? {};

    final double sugar100g = (nutriments['sugars_100g'] as num?)?.toDouble() ??
        (nutriments['sugars_value'] as num?)?.toDouble() ??
        0.0;

    final double? addedSugar100g =
        (nutriments['added-sugars_100g'] as num?)?.toDouble();

    // Parse serving size in grams if available
    double servingG = 30.0;
    if (raw['serving_quantity'] != null) {
      servingG = (raw['serving_quantity'] as num).toDouble();
    } else if (raw['serving_size'] != null) {
      final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(raw['serving_size'].toString());
      if (match != null) {
        servingG = double.tryParse(match.group(1)!) ?? 30.0;
      }
    }

    // Parse pack size in grams if available
    double packG = 100.0;
    if (raw['product_quantity'] != null) {
      packG = (raw['product_quantity'] as num).toDouble();
    } else if (raw['quantity'] != null) {
      final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(raw['quantity'].toString());
      if (match != null) {
        packG = double.tryParse(match.group(1)!) ?? 100.0;
      }
    }

    final name = raw['product_name']?.toString() ??
        raw['product_name_en']?.toString() ??
        'Packaged Food';

    final brand = raw['brands']?.toString() ?? 'Generic';
    final category = raw['categories']?.toString().split(',').first.trim() ?? 'Snacks';

    return Product(
      barcode: barcode,
      name: name,
      brand: brand,
      category: category,
      packSizeG: packG > 0 ? packG : 100.0,
      servingSizeG: servingG > 0 ? servingG : 30.0,
      sugarPer100g: sugar100g >= 0 ? sugar100g : 0.0,
      addedSugarPer100g: addedSugar100g,
      hiddenSugarFlag: false,
      source: 'openfoodfacts',
      verified: false,
    );
  }

  /// Exposes all currently loaded seed products for testing/inspection.
  List<Product> getAllCachedProducts() => _memoryCache.values.toList();
}

/// Riverpod Provider for ProductRepository singleton.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

/// Riverpod FutureProvider for barcode lookup.
final productLookupProvider =
    FutureProvider.autoDispose.family<Product?, String>((ref, barcode) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getProductByBarcode(barcode);
});
