export 'off_repository.dart';
import 'off_repository.dart';
import '../../core/utils/product_alerts_engine.dart';
import '../models/user_preferences.dart';
import '../models/off_product_dto.dart';
import '../models/scan_history_entry.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/models/sugar_swap.dart';
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
      var seedProduct = _seedCache[cleanBarcode]!;
      try {
        final cachedDetails = await _localDb.getProductDetails(cleanBarcode);
        if (cachedDetails != null) {
          seedProduct = seedProduct.copyWith(details: cachedDetails);
        }
        await _localDb.insertScanHistory(ScanHistoryEntry(
          barcode: seedProduct.barcode,
          name: seedProduct.name,
          brand: seedProduct.brand,
          category: seedProduct.category,
          sugarPer100: seedProduct.sugarPer100,
          nutriScoreGrade: seedProduct.nutriScoreGrade,
          novaGroup: seedProduct.novaGroup,
          scannedAt: DateTime.now(),
        ));
      } catch (_) {}
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
          'https://world.openfoodfacts.org/api/v2/product/$candidate.json?fields=code,product_name,brands,quantity,serving_size,image_front_url,image_front_small_url,image_ingredients_url,image_nutrition_url,ingredients_text,ingredients_analysis_tags,allergens_tags,traces_tags,additives_tags,labels_tags,origins,origins_tags,packaging,packaging_tags,categories_tags,nutriments,nutrient_levels,nutriscore_grade,nutriscore_data,nova_group,ecoscore_grade,ecoscore_data,nutrition_data_per',
        );
        debugPrint('[OFF Lookup] Requesting URL: $url');
        final response = await _client.get(
          url,
          headers: {
            'User-Agent': 'Glucio/1.0.0 (com.glucio.app; Android)',
          },
        ).timeout(const Duration(seconds: 5));

        debugPrint('[OFF Lookup] Status: ${response.statusCode} for candidate: $candidate');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final productMap = data['product'] as Map<String, dynamic>?;
          steps.add('OFF API v2 ($candidate): Status 200, product_present=${productMap != null}');

          if (productMap != null) {
            final dto = OffProductDto.fromJson(productMap);
            final p = dto.toProduct();
            _seedCache[cleanBarcode] = p; // cache for session
            try {
              if (p.details != null) {
                await _localDb.saveProductDetails(p.details!);
              }
              await _localDb.insertScanHistory(ScanHistoryEntry(
                barcode: cleanBarcode,
                name: p.name,
                brand: p.brand,
                category: p.category,
                sugarPer100: p.sugarPer100,
                nutriScoreGrade: p.nutriScoreGrade,
                novaGroup: p.novaGroup,
                scannedAt: DateTime.now(),
              ));
            } catch (e) {
              debugPrint('[OFF Lookup] Error caching to SQLite: $e');
            }
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
          steps.add('OFF API v2 ($candidate): Status 404 (Not in Open Food Facts database)');
        } else {
          steps.add('OFF API v2 ($candidate): HTTP ${response.statusCode}');
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


  /// Exposes all currently loaded seed products for testing/inspection.
  List<Product> getAllCachedProducts() => _seedCache.values.toList();

  /// Saves or updates a user-contributed or corrected product.
  Future<void> saveUserProduct(Product product) async {
    await _localDb.saveProduct(product);
    _seedCache[product.barcode] = product;
  }

  /// Returns up to [limit] lower-sugar alternatives for [product] within the same category group,
  /// filtered by user dietary preferences and ranked by sugar, Nutri-Score, and NOVA.
  Future<List<SugarSwap>> getLowerSugarSwaps(
    Product product, {
    int limit = 3,
    UserPreferences? preferences,
  }) async {
    await loadSeedProducts();

    final allProducts = <String, Product>{};
    for (final p in _seedCache.values) {
      allProducts[p.barcode] = p;
    }

    try {
      final userProds = await _localDb.getAllProducts();
      for (final p in userProds) {
        allProducts[p.barcode] = p;
      }
    } catch (_) {}

    final currentSugar = product.sugarPer100;
    final currentGroup = normalizeCategoryGroup(product.category);

    final candidates = <Product>[];

    for (final candidate in allProducts.values) {
      if (candidate.barcode == product.barcode) continue;
      if (candidate.sugarPer100 == null) continue;

      final candidateGroup = normalizeCategoryGroup(candidate.category);
      if (candidateGroup != currentGroup) continue;

      if (currentSugar != null) {
        if (candidate.sugarPer100! < currentSugar) {
          candidates.add(candidate);
        }
      } else {
        if (candidate.sugarPer100! <= 5.0) {
          candidates.add(candidate);
        }
      }
    }

    // Filter out alternatives that violate mandatory user dietary preferences
    if (preferences != null) {
      candidates.removeWhere((c) {
        final verdict = ProductAlertsEngine.evaluate(
          preferences: preferences,
          product: c,
        );
        return verdict.isMandatoryViolation;
      });
    }

    // Primary sort: lowest sugar first
    // Secondary sort: Nutri-Score (A < B < C < D < E) and NOVA (1 < 2 < 3 < 4) when sugar is close
    candidates.sort((a, b) {
      final sugarDiff = a.sugarPer100!.compareTo(b.sugarPer100!);
      final absDiff = (a.sugarPer100! - b.sugarPer100!).abs();
      if (absDiff > 1.0) {
        return sugarDiff;
      }

      final aGrade = a.nutriScoreGrade?.toLowerCase() ?? 'z';
      final bGrade = b.nutriScoreGrade?.toLowerCase() ?? 'z';
      final gradeDiff = aGrade.compareTo(bGrade);
      if (gradeDiff != 0) {
        return gradeDiff;
      }

      final aNova = a.novaGroup ?? 99;
      final bNova = b.novaGroup ?? 99;
      return aNova.compareTo(bNova);
    });

    return candidates
        .take(limit)
        .map((swap) => SugarSwap.fromProducts(original: product, swap: swap))
        .toList();
  }

  /// Normalizes product categories into comparable groups for swap matching.
  static String normalizeCategoryGroup(String category) {
    final c = category.toLowerCase().trim();
    if (c.contains('biscuit') || c.contains('cookie') || c.contains('bakery') || c.contains('bread')) {
      return 'biscuits';
    }
    if (c.contains('beverage') || c.contains('drink') || c.contains('juice') || c.contains('milk') || c.contains('tea') || c.contains('coffee') || c.contains('soda')) {
      return 'beverages';
    }
    if (c.contains('namkeen') || c.contains('chip') || c.contains('crisp') || c.contains('noodle') || c.contains('snack')) {
      return 'snacks';
    }
    if (c.contains('cereal') || c.contains('oat') || c.contains('grain')) {
      return 'cereals';
    }
    if (c.contains('sweet') || c.contains('chocolate') || c.contains('confection') || c.contains('dessert')) {
      return 'confectionery';
    }
    if (c.contains('sauce') || c.contains('ketchup') || c.contains('dip') || c.contains('chutney')) {
      return 'sauces';
    }
    if (c.contains('health drink')) {
      return 'health drinks';
    }
    if (c.contains('yogurt') || c.contains('curd') || c.contains('dairy')) {
      return 'dairy';
    }
    return c;
  }
}

/// Riverpod Provider for ProductRepository singleton.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

/// Riverpod Provider holding the diagnostic trace of the last lookup.
final lastLookupTraceProvider = Provider<LookupTrace?>((ref) {
  return ref.watch(productRepositoryProvider).lastTrace;
});

/// Riverpod FutureProvider for lower-sugar swaps of a given product.
final lowerSugarSwapsProvider =
    FutureProvider.family<List<SugarSwap>, Product>((ref, product) async {
  final repo = ref.watch(productRepositoryProvider);
  final prefsAsync = ref.watch(userPreferencesProvider);
  final prefs = prefsAsync.value;
  return repo.getLowerSugarSwaps(product, preferences: prefs);
});
