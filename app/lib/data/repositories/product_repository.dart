import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/portion_builder.dart';
import '../datasources/local_product_database.dart';
import '../models/product.dart';

/// 4 distinct statuses for barcode lookup results as required by pipeline design.
enum LookupResultStatus {
  success,
  foundMissingSugar,
  notFound,
  networkError,
}

/// Captures diagnostic details for debug builds.
class LookupTrace {
  final String rawBarcode;
  final String barcodeFormat;
  final List<String> steps;
  final String? error;
  final Product? result;
  final LookupResultStatus status;

  const LookupTrace({
    required this.rawBarcode,
    required this.barcodeFormat,
    required this.steps,
    this.error,
    this.result,
    this.status = LookupResultStatus.notFound,
  });

  bool get isFound => result != null;
}

/// Repository responsible for barcode lookups across local user db, seed catalog, and Open Food Facts.
class ProductRepository {
  final http.Client _client;
  final LocalProductDatabase _localDb;
  final Map<String, Product> _seedCache = {};
  bool _seedLoaded = false;
  LookupTrace? lastTrace;

  ProductRepository({
    http.Client? client,
    LocalProductDatabase? localDb,
  })  : _client = client ?? http.Client(),
        _localDb = localDb ?? LocalProductDatabase.instance;

  /// Loads bundled seed products and portion defaults from assets.
  Future<void> loadSeedProducts() async {
    if (_seedLoaded) return;
    try {
      await PortionBuilder.initDefaults();
      final jsonString =
          await rootBundle.loadString('assets/seed_products.json');
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      for (final item in list) {
        final product = Product.fromJson(item as Map<String, dynamic>);
        _seedCache[product.barcode] = product;
      }
      _seedLoaded = true;
      debugPrint('Loaded ${_seedCache.length} seed products into memory cache.');
    } catch (e, stack) {
      debugPrint('Error loading seed products: $e\n$stack');
    }
  }

  /// Identifies the barcode symbology format.
  String _detectFormat(String barcode) {
    if (barcode.length == 8) return 'EAN-8';
    if (barcode.length == 12) return 'UPC-A';
    if (barcode.length == 13) return 'EAN-13';
    return 'EAN/UPC (${barcode.length} digits)';
  }

  /// Looks up a product by barcode following the required priority pipeline:
  /// 1. Local user database (sqflite) -> "Added by you"
  /// 2. Seed catalog / in-memory cache
  /// 3. Open Food Facts v2 API (with UPC-A leading-0 & EAN-8 fallback)
  Future<Product?> getProductByBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return null;

    final format = _detectFormat(cleanBarcode);
    final List<String> steps = [];
    String? traceError;

    // Ensure seed products are loaded
    if (!_seedLoaded) {
      await loadSeedProducts();
    }

    // 1. Check local user database first
    try {
      final userProduct = await _localDb.getProduct(cleanBarcode);
      if (userProduct != null) {
        steps.add('Local User DB: HIT (${userProduct.name})');
        final status = userProduct.sugarPer100 != null
            ? LookupResultStatus.success
            : LookupResultStatus.foundMissingSugar;
        final trace = LookupTrace(
          rawBarcode: cleanBarcode,
          barcodeFormat: format,
          steps: steps,
          result: userProduct,
          status: status,
        );
        lastTrace = trace;
        return userProduct;
      } else {
        steps.add('Local User DB: MISS');
      }
    } catch (e) {
      steps.add('Local User DB error: $e');
    }

    // 2. Check bundled seed catalog
    if (_seedCache.containsKey(cleanBarcode)) {
      final seedProduct = _seedCache[cleanBarcode]!;
      steps.add('Seed Catalog: HIT (${seedProduct.name})');
      final status = seedProduct.sugarPer100 != null
          ? LookupResultStatus.success
          : LookupResultStatus.foundMissingSugar;
      final trace = LookupTrace(
        rawBarcode: cleanBarcode,
        barcodeFormat: format,
        steps: steps,
        result: seedProduct,
        status: status,
      );
      lastTrace = trace;
      return seedProduct;
    } else {
      steps.add('Seed Catalog: MISS');
    }

    // 3. Query Open Food Facts v3 API
    // Candidates to query: raw code, and zero-padded variations
    final List<String> queryCandidates = [cleanBarcode];
    if (cleanBarcode.length == 12) {
      // UPC-A -> try 13-digit EAN-13 with leading 0
      queryCandidates.add('0$cleanBarcode');
    } else if (cleanBarcode.length == 8) {
      // EAN-8 -> also try 13-digit padded form
      queryCandidates.add(cleanBarcode.padLeft(13, '0'));
    }

    for (final candidate in queryCandidates) {
      try {
        final url = Uri.parse(
          'https://world.openfoodfacts.org/api/v3/product/$candidate.json?fields=product_name,product_name_en,brands,categories,quantity,serving_size,serving_quantity,product_quantity,nutriments,nutrition_data_per',
        );
        debugPrint('[OFF Lookup] Requesting URL: $url');
        final response = await _client.get(
          url,
          headers: {
            'User-Agent': 'Glucio - Android - Version 1.5 (Student Pair Programming)',
          },
        ).timeout(const Duration(seconds: 5));

        debugPrint('[OFF Lookup] Status: ${response.statusCode} for candidate: $candidate');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final productMap = data['product'] as Map<String, dynamic>?;
          steps.add('OFF API v3 ($candidate): Status 200, product_present=${productMap != null}');

          if (productMap != null) {
            final p = _parseOpenFoodFacts(
              cleanBarcode,
              productMap,
            );
            _seedCache[cleanBarcode] = p; // cache for session
            final status = p.sugarPer100 != null
                ? LookupResultStatus.success
                : LookupResultStatus.foundMissingSugar;
            final trace = LookupTrace(
              rawBarcode: cleanBarcode,
              barcodeFormat: format,
              steps: steps,
              result: p,
              status: status,
            );
            lastTrace = trace;
            return p;
          }
        } else if (response.statusCode == 404) {
          steps.add('OFF API v3 ($candidate): Status 404 (Not in Open Food Facts database)');
        } else {
          steps.add('OFF API v3 ($candidate): HTTP ${response.statusCode}');
        }
      } on TimeoutException {
        traceError = 'Network timeout contacting Open Food Facts (5s exceeded)';
        steps.add('OFF API v3 ($candidate): TIMEOUT');
        debugPrint('[OFF Lookup] Timeout connecting to Open Food Facts');
      } on SocketException catch (se) {
        traceError = 'Device appears offline or network unreachable ($se)';
        steps.add('OFF API v3 ($candidate): OFFLINE/NETWORK_ERROR');
        debugPrint('[OFF Lookup] SocketException: $se');
      } catch (e) {
        traceError = 'Lookup error: $e';
        steps.add('OFF API v3 ($candidate): ERROR ($e)');
        debugPrint('[OFF Lookup] Exception: $e');
      }
    }

    final LookupResultStatus finalStatus;
    if (traceError != null &&
        (traceError.contains('offline') ||
            traceError.contains('timeout') ||
            traceError.contains('Network') ||
            traceError.contains('SocketException'))) {
      finalStatus = LookupResultStatus.networkError;
    } else {
      finalStatus = LookupResultStatus.notFound;
    }

    final trace = LookupTrace(
      rawBarcode: cleanBarcode,
      barcodeFormat: format,
      steps: steps,
      error: traceError,
      result: null,
      status: finalStatus,
    );
    lastTrace = trace;
    return null;
  }

  /// Parses Open Food Facts raw product JSON into domain Product model.
  /// Strictly keeps sugarPer100 as null if not explicitly declared in nutriments.
  Product _parseOpenFoodFacts(String barcode, Map<String, dynamic> raw) {
    final nutriments = raw['nutriments'] as Map<String, dynamic>? ?? {};

    // RULE: Missing or unknown nutrition values must NEVER be defaulted to 0
    double? sugar100;
    if (nutriments['sugars_100g'] != null) {
      sugar100 = (nutriments['sugars_100g'] as num?)?.toDouble();
    } else if (nutriments['sugars_value'] != null) {
      sugar100 = (nutriments['sugars_value'] as num?)?.toDouble();
    }

    final double? addedSugar100 =
        (nutriments['added-sugars_100g'] as num?)?.toDouble();

    // Parse serving size in grams if available
    double servingG = 30.0;
    String? servingDescription;
    if (raw['serving_quantity'] != null) {
      servingG = (raw['serving_quantity'] as num).toDouble();
    } else if (raw['serving_size'] != null) {
      final sSize = raw['serving_size'].toString();
      servingDescription = sSize;
      final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(sSize);
      if (match != null) {
        servingG = double.tryParse(match.group(1)!) ?? 30.0;
      }
    }

    // Parse pack size in grams if available
    double packG = 100.0;
    if (raw['product_quantity'] != null) {
      packG = (raw['product_quantity'] as num).toDouble();
    } else if (raw['quantity'] != null) {
      final match =
          RegExp(r'(\d+(\.\d+)?)').firstMatch(raw['quantity'].toString());
      if (match != null) {
        packG = double.tryParse(match.group(1)!) ?? 100.0;
      }
    }

    final name = raw['product_name']?.toString() ??
        raw['product_name_en']?.toString() ??
        'Packaged Food';

    final brand = raw['brands']?.toString() ?? 'Generic';
    final category =
        raw['categories']?.toString().split(',').first.trim() ?? 'Snacks';

    // Derive sugar basis from nutrition_data_per or quantity unit without guessing
    final nutDataPer = raw['nutrition_data_per']?.toString().toLowerCase().trim();
    final qtyStr = raw['quantity']?.toString().toLowerCase().trim() ?? '';
    final isLiquid = nutDataPer == '100ml' ||
        qtyStr.contains('ml') ||
        category.toLowerCase().contains('beverage') ||
        category.toLowerCase().contains('drink');

    final basis = isLiquid ? 'per_100ml' : 'per_100g';

    final portions = PortionBuilder.buildPortions(
      category: category,
      packSize: packG,
      servingSize: servingG,
      servingDescription: servingDescription,
      basis: isLiquid ? 'ml' : 'g',
    );

    return Product(
      barcode: barcode,
      name: name,
      brand: brand,
      category: category,
      packSize: packG > 0 ? packG : 100.0,
      servingSize: servingG > 0 ? servingG : 30.0,
      sugarPer100: sugar100,
      addedSugarPer100: addedSugar100,
      sugarBasis: basis,
      portions: portions,
      hiddenSugarFlag: false,
      source: 'openfoodfacts',
      verified: false,
    );
  }

  /// Exposes all currently loaded seed products for testing/inspection.
  List<Product> getAllCachedProducts() => _seedCache.values.toList();
}

/// Riverpod Provider for ProductRepository singleton.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

/// Riverpod Provider holding the diagnostic trace of the last lookup.
final lastLookupTraceProvider = Provider<LookupTrace?>((ref) {
  return ref.watch(productRepositoryProvider).lastTrace;
});
