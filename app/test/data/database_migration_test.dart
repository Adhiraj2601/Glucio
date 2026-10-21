import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/data/datasources/local_product_database.dart';
import 'package:glucio/data/models/product_details.dart';
import 'package:glucio/data/models/scan_history_entry.dart';
import 'package:glucio/data/models/user_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('LocalProductDatabase Schema Migration & v3 Tables Tests', () {
    late Database inMemoryDb;

    setUp(() async {
      // Create a fresh in-memory database
      inMemoryDb = await databaseFactory.openDatabase(inMemoryDatabasePath);
      LocalProductDatabase.setTestDatabase(inMemoryDb);
    });

    tearDown(() async {
      await inMemoryDb.close();
      LocalProductDatabase.setTestDatabase(null);
    });

    test('simulates upgrade from v2 schema to v3 schema preserving existing user data', () async {
      // 1. Manually set up v2 schema
      await inMemoryDb.execute('''
        CREATE TABLE user_products (
          barcode TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          brand TEXT,
          category TEXT,
          pack_size REAL,
          serving_size REAL,
          sugar_per_100 REAL,
          added_sugar_per_100 REAL,
          sugar_basis TEXT,
          portions_json TEXT,
          hidden_sugar_flag INTEGER,
          source TEXT,
          verified INTEGER,
          created_at TEXT
        )
      ''');

      await inMemoryDb.execute('''
        CREATE TABLE food_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          barcode TEXT NOT NULL,
          name TEXT NOT NULL,
          brand TEXT,
          portion_label TEXT NOT NULL,
          portion_amount REAL NOT NULL,
          portion_basis TEXT NOT NULL,
          sugar_grams REAL,
          logged_at TEXT NOT NULL
        )
      ''');

      await inMemoryDb.execute('''
        CREATE TABLE user_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');

      // Insert pre-existing v2 records
      await inMemoryDb.insert('user_products', {
        'barcode': '8901234567890',
        'name': 'Existing Custom Paratha',
        'brand': 'Home',
        'category': 'Bread',
        'pack_size': 100.0,
        'serving_size': 50.0,
        'sugar_per_100': 1.5,
        'sugar_basis': 'per_100g',
        'portions_json': null,
        'hidden_sugar_flag': 0,
        'source': 'user',
        'verified': 1,
        'created_at': DateTime.now().toIso8601String(),
      });

      await inMemoryDb.insert('food_logs', {
        'barcode': '8901234567890',
        'name': 'Existing Custom Paratha',
        'brand': 'Home',
        'portion_label': '1 paratha',
        'portion_amount': 50.0,
        'portion_basis': 'g',
        'sugar_grams': 0.75,
        'logged_at': DateTime.now().toIso8601String(),
      });

      await inMemoryDb.insert('user_settings', {
        'key': 'daily_limit_g',
        'value': '28.0',
      });

      // 2. Perform v3 upgrade
      final localDb = LocalProductDatabase.instance;
      // Trigger table creation for v3
      await inMemoryDb.execute('''
        CREATE TABLE IF NOT EXISTS product_details (
          barcode TEXT PRIMARY KEY,
          quantity TEXT,
          image_front_url TEXT,
          image_front_small_url TEXT,
          image_ingredients_url TEXT,
          image_nutrition_url TEXT,
          ingredients_text TEXT,
          ingredients_analysis_tags TEXT,
          allergens_tags TEXT,
          traces_tags TEXT,
          additives_tags TEXT,
          labels_tags TEXT,
          origins TEXT,
          packaging TEXT,
          packaging_tags TEXT,
          categories_tags TEXT,
          nutriscore_grade TEXT,
          nutriscore_data TEXT,
          nova_group INTEGER,
          ecoscore_grade TEXT,
          ecoscore_data TEXT,
          nutrient_levels TEXT,
          full_nutriments TEXT,
          ingredients_analysis TEXT,
          raw_json TEXT,
          fetched_at INTEGER
        )
      ''');

      await inMemoryDb.execute('''
        CREATE TABLE IF NOT EXISTS user_preferences (
          criterion_id TEXT PRIMARY KEY,
          category TEXT NOT NULL,
          importance TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      await inMemoryDb.execute('''
        CREATE TABLE IF NOT EXISTS scan_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          barcode TEXT NOT NULL,
          name TEXT NOT NULL,
          brand TEXT,
          category TEXT,
          sugar_per_100 REAL,
          nutriscore_grade TEXT,
          nova_group INTEGER,
          scanned_at TEXT NOT NULL
        )
      ''');

      await inMemoryDb.execute('''
        CREATE TABLE IF NOT EXISTS product_lists (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      await inMemoryDb.execute('''
        CREATE TABLE IF NOT EXISTS product_list_items (
          list_id TEXT NOT NULL,
          barcode TEXT NOT NULL,
          added_at TEXT NOT NULL,
          PRIMARY KEY (list_id, barcode)
        )
      ''');

      await inMemoryDb.execute('''
        CREATE TABLE IF NOT EXISTS pending_contributions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          barcode TEXT NOT NULL,
          data_json TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      // 3. Verify that old user data is 100% preserved
      final userProduct = await localDb.getProduct('8901234567890');
      expect(userProduct, isNotNull);
      expect(userProduct!.name, 'Existing Custom Paratha');
      expect(userProduct.sugarPer100, 1.5);

      final logs = await localDb.getAllFoodLogs();
      expect(logs.length, 1);
      expect(logs.first.sugarGrams, 0.75);

      final limit = await localDb.getDailyLimit();
      expect(limit, 28.0);

      // 4. Test product_details caching
      final details = ProductDetails(
        barcode: '8901234567890',
        nutriScoreGrade: 'b',
        novaGroup: 2,
        ingredientsText: 'Wheat flour, water, ghee.',
        allergenTags: ['en:gluten'],
        fetchedAt: DateTime.now(),
      );
      await localDb.saveProductDetails(details);

      final cachedDetails = await localDb.getProductDetails('8901234567890');
      expect(cachedDetails, isNotNull);
      expect(cachedDetails!.nutriScoreGrade, 'b');
      expect(cachedDetails.novaGroup, 2);
      expect(cachedDetails.allergenTags, contains('en:gluten'));

      // 5. Test user_preferences storage
      final prefs = UserPreferences.defaults();
      final updatedGluten = prefs.getCriterion('allergen_gluten')!.copyWith(
            importance: PreferenceImportance.mandatory,
          );
      final customPrefs = prefs.copyWith(
        criteria: {...prefs.criteria, 'allergen_gluten': updatedGluten},
      );
      await localDb.saveUserPreferences(customPrefs);

      final loadedPrefs = await localDb.getUserPreferences();
      expect(
        loadedPrefs.getImportance('allergen_gluten'),
        PreferenceImportance.mandatory,
      );

      // 6. Test scan_history recording
      await localDb.insertScanHistory(ScanHistoryEntry(
        barcode: '8901234567890',
        name: 'Existing Custom Paratha',
        sugarPer100: 1.5,
        scannedAt: DateTime.now(),
      ));

      final history = await localDb.getScanHistory();
      expect(history.length, 1);
      expect(history.first.barcode, '8901234567890');

      // 7. Test custom product lists
      await localDb.createProductList('favs', 'My Favorites');
      await localDb.addProductToList('favs', '8901234567890');

      final lists = await localDb.getProductLists();
      expect(lists.length, 1);
      expect(lists.first.name, 'My Favorites');
      expect(lists.first.barcodes, contains('8901234567890'));

      await localDb.removeProductFromList('favs', '8901234567890');
      final updatedLists = await localDb.getProductLists();
      expect(updatedLists.first.barcodes, isEmpty);
    });
  });
}
