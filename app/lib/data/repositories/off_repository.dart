import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/product_alerts_engine.dart';
import '../datasources/local_product_database.dart';
import '../models/product.dart';
import '../models/product_alert_verdict.dart';
import '../models/product_details.dart';
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
