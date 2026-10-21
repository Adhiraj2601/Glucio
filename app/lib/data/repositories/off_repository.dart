import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/product_alerts_engine.dart';
import '../datasources/local_product_database.dart';
import '../models/off_product_dto.dart';
import '../models/product.dart';
import '../models/product_alert_verdict.dart';
import '../models/product_details.dart';
import '../models/product_list.dart';
import '../models/scan_history_entry.dart';
import '../models/user_preferences.dart';
import 'product_repository.dart';

/// Repository coordinating Open Food Facts enriched data, user preferences, and scan history.
class OffRepository {
  final ProductRepository _productRepo;
  final LocalProductDatabase _localDb;

  OffRepository({
    ProductRepository? productRepo,
    LocalProductDatabase? localDb,
  })  : _productRepo = productRepo ?? ProductRepository(),
        _localDb = localDb ?? LocalProductDatabase.instance;

  /// Fetches product details following the offline-first hierarchy:
  /// 1. Local SQLite cache (`product_details`)
  /// 2. If missing, invokes ProductRepository (which queries OFF live and caches to SQLite)
  Future<ProductDetails?> getProductDetails(String barcode) async {
    final clean = barcode.trim();
    if (clean.isEmpty) return null;

    final cached = await _localDb.getProductDetails(clean);
    if (cached != null) return cached;

    final product = await _productRepo.getProductByBarcode(clean);
    return product?.details;
  }

  /// Saves enriched product details to local SQLite cache.
  Future<void> saveProductDetails(ProductDetails details) =>
      _localDb.saveProductDetails(details);

  /// Loads current user preferences from SQLite.
  Future<UserPreferences> getUserPreferences() => _localDb.getUserPreferences();

  /// Saves user preferences to SQLite.
  Future<void> saveUserPreferences(UserPreferences prefs) =>
      _localDb.saveUserPreferences(prefs);

  /// Retrieves chronological scan history.
  Future<List<ScanHistoryEntry>> getScanHistory({int limit = 100}) =>
      _localDb.getScanHistory(limit: limit);

  /// Records a product scan into history.
  Future<void> recordScan(Product product) async {
    await _localDb.insertScanHistory(
      ScanHistoryEntry(
        barcode: product.barcode,
        name: product.name,
        brand: product.brand,
        category: product.category,
        sugarPer100: product.sugarPer100,
        nutriScoreGrade: product.nutriScoreGrade,
        novaGroup: product.novaGroup,
        scannedAt: DateTime.now(),
      ),
    );
  }

  /// Searches products against local SQLite/seed catalog and Open Food Facts search API.
  Future<List<Product>> searchProducts(
    String query, {
    bool indiaOnly = true,
    String? category,
    http.Client? client,
  }) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return const [];

    final resultsMap = <String, Product>{};

    // 1. Search local seed products & SQLite cache
    final localSeed = await _productRepo.getSeedProducts();
    for (final p in localSeed.values) {
      final nameMatches = p.name.toLowerCase().contains(clean);
      final brandMatches = p.brand.toLowerCase().contains(clean);
      final barcodeMatches = p.barcode.contains(clean);

      if (nameMatches || brandMatches || barcodeMatches) {
        if (category == null ||
            category.isEmpty ||
            p.category.toLowerCase().contains(category.toLowerCase())) {
          resultsMap[p.barcode] = p;
        }
      }
    }

    // 2. Query Open Food Facts search API if query is 2+ characters
    if (clean.length >= 2) {
      final httpClient = client ?? http.Client();
      try {
        final uri = Uri.parse(
          'https://world.openfoodfacts.org/cgi/search.pl?'
          'search_terms=${Uri.encodeComponent(clean)}&'
          'search_simple=1&action=process&json=1&page_size=25'
          '${indiaOnly ? "&countries_tags_en=india" : ""}&'
          'fields=code,product_name,brands,quantity,serving_size,image_front_small_url,image_front_url,ingredients_text,ingredients_analysis_tags,allergens_tags,traces_tags,additives_tags,labels_tags,origins,origins_tags,packaging,packaging_tags,categories_tags,nutriments,nutrient_levels,nutriscore_grade,nutriscore_data,nova_group,ecoscore_grade,ecoscore_data,nutrition_data_per',
        );

        final response = await httpClient
            .get(uri, headers: {'User-Agent': 'Glucio/1.0.0 (com.glucio.app; Android)'})
            .timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic> && data['products'] is List) {
            for (final item in data['products']) {
              if (item is Map<String, dynamic>) {
                final dto = OffProductDto.fromJson(item);
                final prod = dto.toProduct();
                if (prod.barcode.isNotEmpty && !resultsMap.containsKey(prod.barcode)) {
                  if (category == null ||
                      category.isEmpty ||
                      prod.category.toLowerCase().contains(category.toLowerCase())) {
                    resultsMap[prod.barcode] = prod;
                    if (prod.details != null) {
                      _localDb.saveProductDetails(prod.details!);
                    }
                  }
                }
              }
            }
          }
        }
      } catch (_) {
        // Fallback gracefully to offline seed/cache matches on network failure
      } finally {
        if (client == null) httpClient.close();
      }
    }

    return resultsMap.values.toList();
  }

  /// Queues a product contribution for background offline sync.
  Future<int> queueContribution({
    required String barcode,
    required Map<String, dynamic> data,
  }) =>
      _localDb.queuePendingContribution(barcode, data);

  /// Retrieves all queued contributions from SQLite.
  Future<List<Map<String, dynamic>>> getPendingContributions() =>
      _localDb.getPendingContributions();

  /// Submits an edit or product creation to Open Food Facts v2 write API.
  Future<bool> uploadContribution({
    required String barcode,
    required Map<String, dynamic> data,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      final uri = Uri.parse('https://world.openfoodfacts.org/cgi/product_jqm2.pl');
      final response = await httpClient.post(
        uri,
        headers: {
          'User-Agent': 'Glucio/1.0.0 (com.glucio.app; Android)',
        },
        body: {
          'code': barcode,
          'product_name': data['product_name'] ?? '',
          'brands': data['brands'] ?? '',
          'ingredients_text': data['ingredients_text'] ?? '',
          'nutriment_sugars': data['sugars']?.toString() ?? '',
          'nutriment_energy-kcal': data['energy']?.toString() ?? '',
          'comment': 'Contributed via Glucio App',
        },
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      if (client == null) httpClient.close();
    }
  }

  /// Iterates through queued contributions in SQLite and attempts to sync them.
  Future<int> syncPendingContributions({http.Client? client}) async {
    final pending = await _localDb.getPendingContributions();
    int syncedCount = 0;
    for (final item in pending) {
      final id = item['id'] as int;
      final barcode = item['barcode'] as String;
      final data = jsonDecode(item['data_json'] as String) as Map<String, dynamic>;
      final success = await uploadContribution(
        barcode: barcode,
        data: data,
        client: client,
      );
      if (success) {
        await _localDb.removePendingContribution(id);
        syncedCount++;
      }
    }
    return syncedCount;
  }
}

// ==========================================
// RIVERPOD NOTIFIERS & PROVIDERS
// ==========================================

/// Riverpod Provider for OffRepository.
final offRepositoryProvider = Provider<OffRepository>((ref) {
  final productRepo = ref.watch(productRepositoryProvider);
  return OffRepository(productRepo: productRepo);
});

/// Riverpod FutureProvider returning enriched product details by barcode.
final productDetailsProvider =
    FutureProvider.family<ProductDetails?, String>((ref, barcode) async {
  final repo = ref.watch(offRepositoryProvider);
  return repo.getProductDetails(barcode);
});

/// Riverpod FutureProvider returning nutrition quality data (Nutri-Score, NOVA, Eco-Score, Nutrient Levels).
final nutritionQualityProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, barcode) async {
  final details = await ref.watch(productDetailsProvider(barcode).future);
  return {
    'nutriscore_grade': details?.nutriScoreGrade,
    'nutriscore_data': details?.nutriScoreData,
    'nova_group': details?.novaGroup,
    'ecoscore_grade': details?.ecoScoreGrade,
    'nutrient_levels': details?.nutrientLevels?.toJson(),
  };
});

/// AsyncNotifier managing user dietary preferences state.
class UserPreferencesNotifier extends AsyncNotifier<UserPreferences> {
  @override
  Future<UserPreferences> build() async {
    return await LocalProductDatabase.instance.getUserPreferences();
  }

  Future<void> updateCriterion(String id, PreferenceImportance importance) async {
    final current = state.value ?? UserPreferences.defaults();
    final existing = current.getCriterion(id);
    if (existing == null) return;
    final updated = existing.copyWith(
      importance: importance,
      updatedAt: DateTime.now(),
    );
    final newMap = Map<String, PreferenceCriterion>.from(current.criteria)..[id] = updated;
    final next = current.copyWith(criteria: newMap);
    await LocalProductDatabase.instance.saveUserPreferences(next);
    state = AsyncData(next);
  }

  Future<void> resetToDefaults() async {
    final defaults = UserPreferences.defaults();
    await LocalProductDatabase.instance.saveUserPreferences(defaults);
    state = AsyncData(defaults);
  }
}

/// Riverpod AsyncNotifierProvider for user preferences.
final userPreferencesProvider =
    AsyncNotifierProvider<UserPreferencesNotifier, UserPreferences>(
        UserPreferencesNotifier.new);

/// Notifier managing active products in comparison (between 2 and 4 products).
class ProductCompareNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() => [];

  bool addProduct(Product product) {
    if (state.length >= 4) return false;
    if (state.any((p) => p.barcode == product.barcode)) return true;
    state = [...state, product];
    return true;
  }

  void removeProduct(String barcode) {
    state = state.where((p) => p.barcode != barcode).toList();
  }

  void clear() {
    state = [];
  }
}

/// Riverpod NotifierProvider for product comparison.
final productCompareProvider =
    NotifierProvider<ProductCompareNotifier, List<Product>>(
        ProductCompareNotifier.new);

/// Riverpod FutureProvider evaluating product compatibility against user preferences.
final productAlertsProvider =
    FutureProvider.family<ProductAlertVerdict, String>((ref, barcode) async {
  final details = await ref.watch(productDetailsProvider(barcode).future);
  final prefsAsync = ref.watch(userPreferencesProvider);
  final prefs = prefsAsync.value ?? UserPreferences.defaults();
  return ProductAlertsEngine.evaluate(preferences: prefs, details: details);
});

/// AsyncNotifier managing scan history list.
class ScanHistoryNotifier extends AsyncNotifier<List<ScanHistoryEntry>> {
  @override
  Future<List<ScanHistoryEntry>> build() async {
    return await LocalProductDatabase.instance.getScanHistory();
  }

  Future<void> recordScan(Product product) async {
    await LocalProductDatabase.instance.insertScanHistory(
      ScanHistoryEntry(
        barcode: product.barcode,
        name: product.name,
        brand: product.brand,
        category: product.category,
        sugarPer100: product.sugarPer100,
        nutriScoreGrade: product.nutriScoreGrade,
        novaGroup: product.novaGroup,
        scannedAt: DateTime.now(),
      ),
    );
    state = AsyncData(await LocalProductDatabase.instance.getScanHistory());
  }

  Future<void> clearHistory() async {
    await LocalProductDatabase.instance.clearScanHistory();
    state = const AsyncData([]);
  }

  Future<void> refresh() async {
    state = AsyncData(await LocalProductDatabase.instance.getScanHistory());
  }
}

final scanHistoryProvider =
    AsyncNotifierProvider<ScanHistoryNotifier, List<ScanHistoryEntry>>(
        ScanHistoryNotifier.new);

/// AsyncNotifier managing user custom product lists.
class ProductListsNotifier extends AsyncNotifier<List<ProductList>> {
  @override
  Future<List<ProductList>> build() async {
    return await LocalProductDatabase.instance.getProductLists();
  }

  Future<void> createList(String name) async {
    final id = 'list_${DateTime.now().millisecondsSinceEpoch}';
    await LocalProductDatabase.instance.createProductList(id, name);
    state = AsyncData(await LocalProductDatabase.instance.getProductLists());
  }

  Future<void> deleteList(String id) async {
    await LocalProductDatabase.instance.deleteProductList(id);
    state = AsyncData(await LocalProductDatabase.instance.getProductLists());
  }

  Future<void> addProduct(String listId, String barcode) async {
    await LocalProductDatabase.instance.addProductToList(listId, barcode);
    state = AsyncData(await LocalProductDatabase.instance.getProductLists());
  }

  Future<void> removeProduct(String listId, String barcode) async {
    await LocalProductDatabase.instance.removeProductFromList(listId, barcode);
    state = AsyncData(await LocalProductDatabase.instance.getProductLists());
  }

  Future<void> refresh() async {
    state = AsyncData(await LocalProductDatabase.instance.getProductLists());
  }
}

final productListsProvider =
    AsyncNotifierProvider<ProductListsNotifier, List<ProductList>>(
        ProductListsNotifier.new);

/// AsyncNotifier managing the offline sync queue for community contributions.
class PendingContributionsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return await LocalProductDatabase.instance.getPendingContributions();
  }

  Future<void> queueContribution({
    required String barcode,
    required Map<String, dynamic> data,
  }) async {
    await LocalProductDatabase.instance.queuePendingContribution(barcode, data);
    state = AsyncData(await LocalProductDatabase.instance.getPendingContributions());
  }

  Future<int> syncQueue({http.Client? client}) async {
    final repo = ref.read(offRepositoryProvider);
    final count = await repo.syncPendingContributions(client: client);
    state = AsyncData(await LocalProductDatabase.instance.getPendingContributions());
    return count;
  }

  Future<void> refresh() async {
    state = AsyncData(await LocalProductDatabase.instance.getPendingContributions());
  }
}

final pendingContributionsProvider =
    AsyncNotifierProvider<PendingContributionsNotifier, List<Map<String, dynamic>>>(
        PendingContributionsNotifier.new);
