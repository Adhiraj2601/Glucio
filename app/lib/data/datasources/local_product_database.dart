import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/food_log_entry.dart';
import '../models/portion.dart';
import '../models/product.dart';
import '../models/product_details.dart';
import '../models/product_list.dart';
import '../models/scan_history_entry.dart';
import '../models/user_preferences.dart';

/// Local SQLite database managing user-added products, food logs, user settings,
/// extended Open Food Facts product details, user preferences, and scan history.
class LocalProductDatabase {
  static final LocalProductDatabase instance = LocalProductDatabase._init();
  static Database? _database;

  LocalProductDatabase._init();

  @visibleForTesting
  static void setTestDatabase(Database? db) {
    _database = db;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('glucio_user_products.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
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

    await _createV2Tables(db);
    await _createV3Tables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createV2Tables(db);
    }
    if (oldVersion < 3) {
      await _createV3Tables(db);
    }
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS food_logs (
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createV3Tables(Database db) async {
    await db.execute('''
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_preferences (
        criterion_id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        importance TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_lists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_list_items (
        list_id TEXT NOT NULL,
        barcode TEXT NOT NULL,
        added_at TEXT NOT NULL,
        PRIMARY KEY (list_id, barcode)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_contributions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT NOT NULL,
        data_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ==========================================
  // USER PRODUCTS
  // ==========================================

  /// Inserts or updates a user-added product.
  Future<void> saveProduct(Product product) async {
    final db = await database;
    await db.insert(
      'user_products',
      {
        'barcode': product.barcode,
        'name': product.name,
        'brand': product.brand,
        'category': product.category,
        'pack_size': product.packSize,
        'serving_size': product.servingSize,
        'sugar_per_100': product.sugarPer100,
        'added_sugar_per_100': product.addedSugarPer100,
        'sugar_basis': product.sugarBasis,
        'portions_json': jsonEncode(product.portions.map((p) => p.toJson()).toList()),
        'hidden_sugar_flag': product.hiddenSugarFlag ? 1 : 0,
        'source': product.source,
        'verified': product.verified ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (product.details != null) {
      await saveProductDetails(product.details!);
    }
  }

  /// Looks up a product by barcode in the local user database.
  Future<Product?> getProduct(String barcode) async {
    final db = await database;
    final maps = await db.query(
      'user_products',
      where: 'barcode = ?',
      whereArgs: [barcode.trim()],
    );

    if (maps.isNotEmpty) {
      final row = maps.first;
      List<Portion> portions = [];
      if (row['portions_json'] != null) {
        try {
          final list = jsonDecode(row['portions_json'] as String) as List<dynamic>;
          portions = list
              .map((item) => Portion.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }

      final details = await getProductDetails(barcode.trim());

      return Product(
        barcode: row['barcode'] as String,
        name: row['name'] as String,
        brand: (row['brand'] as String?) ?? 'Generic',
        category: (row['category'] as String?) ?? 'Snacks',
        packSize: (row['pack_size'] as num?)?.toDouble() ?? 100.0,
        servingSize: (row['serving_size'] as num?)?.toDouble() ?? 30.0,
        sugarPer100: (row['sugar_per_100'] as num?)?.toDouble(),
        addedSugarPer100: (row['added_sugar_per_100'] as num?)?.toDouble(),
        sugarBasis: (row['sugar_basis'] as String?) ?? 'per_100g',
        portions: portions,
        hiddenSugarFlag: (row['hidden_sugar_flag'] as int?) == 1,
        source: (row['source'] as String?) ?? 'user',
        verified: (row['verified'] as int?) == 1,
        details: details,
      );
    }
    return null;
  }

  /// Returns all user-added products.
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('user_products', orderBy: 'created_at DESC');
    final products = <Product>[];
    for (final row in maps) {
      List<Portion> portions = [];
      if (row['portions_json'] != null) {
        try {
          final list = jsonDecode(row['portions_json'] as String) as List<dynamic>;
          portions = list
              .map((item) => Portion.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }

      final barcode = row['barcode'] as String;
      final details = await getProductDetails(barcode);

      products.add(Product(
        barcode: barcode,
        name: row['name'] as String,
        brand: (row['brand'] as String?) ?? 'Generic',
        category: (row['category'] as String?) ?? 'Snacks',
        packSize: (row['pack_size'] as num?)?.toDouble() ?? 100.0,
        servingSize: (row['serving_size'] as num?)?.toDouble() ?? 30.0,
        sugarPer100: (row['sugar_per_100'] as num?)?.toDouble(),
        addedSugarPer100: (row['added_sugar_per_100'] as num?)?.toDouble(),
        sugarBasis: (row['sugar_basis'] as String?) ?? 'per_100g',
        portions: portions,
        hiddenSugarFlag: (row['hidden_sugar_flag'] as int?) == 1,
        source: (row['source'] as String?) ?? 'user',
        verified: (row['verified'] as int?) == 1,
        details: details,
      ));
    }
    return products;
  }

  // ==========================================
  // EXTENDED PRODUCT DETAILS (OFF CACHE)
  // ==========================================

  /// Inserts or replaces enriched product details from Open Food Facts.
  Future<void> saveProductDetails(ProductDetails details) async {
    final db = await database;
    await db.insert(
      'product_details',
      {
        'barcode': details.barcode,
        'quantity': details.quantity,
        'image_front_url': details.imageUrls.front,
        'image_front_small_url': details.imageUrls.frontSmall,
        'image_ingredients_url': details.imageUrls.ingredients,
        'image_nutrition_url': details.imageUrls.nutrition,
        'ingredients_text': details.ingredientsText,
        'ingredients_analysis_tags': jsonEncode(details.ingredientsAnalysisTags),
        'allergens_tags': jsonEncode(details.allergenTags),
        'traces_tags': jsonEncode(details.traceTags),
        'additives_tags': jsonEncode(details.additiveTags),
        'labels_tags': jsonEncode(details.labelTags),
        'origins': details.origins,
        'packaging': details.packaging,
        'packaging_tags': jsonEncode(details.packagingTags),
        'categories_tags': jsonEncode(details.categoriesTags),
        'nutriscore_grade': details.nutriScoreGrade,
        'nutriscore_data': details.nutriScoreData != null ? jsonEncode(details.nutriScoreData) : null,
        'nova_group': details.novaGroup,
        'ecoscore_grade': details.ecoScoreGrade,
        'ecoscore_data': details.ecoScoreData != null ? jsonEncode(details.ecoScoreData) : null,
        'nutrient_levels': details.nutrientLevels != null ? jsonEncode(details.nutrientLevels!.toJson()) : null,
        'full_nutriments': details.fullNutriments != null ? jsonEncode(details.fullNutriments!.toJson()) : null,
        'ingredients_analysis': details.ingredientsAnalysis != null ? jsonEncode(details.ingredientsAnalysis!.toJson()) : null,
        'raw_json': details.rawOffJson,
        'fetched_at': details.fetchedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves cached product details for a given barcode.
  Future<ProductDetails?> getProductDetails(String barcode) async {
    final db = await database;
    final maps = await db.query(
      'product_details',
      where: 'barcode = ?',
      whereArgs: [barcode.trim()],
    );

    if (maps.isNotEmpty) {
      return ProductDetails.fromJson(maps.first);
    }
    return null;
  }

  // ==========================================
  // USER PREFERENCES (SLICE 4 OFF PARITY)
  // ==========================================

  /// Saves the complete set of user preferences.
  Future<void> saveUserPreferences(UserPreferences prefs) async {
    final db = await database;
    final batch = db.batch();
    for (final criterion in prefs.criteria.values) {
      batch.insert(
        'user_preferences',
        criterion.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Loads stored user preferences, merging with defaults if absent.
  Future<UserPreferences> getUserPreferences() async {
    final db = await database;
    final maps = await db.query('user_preferences');
    final defaults = UserPreferences.defaults();

    if (maps.isEmpty) {
      return defaults;
    }

    final updatedCriteria = Map<String, PreferenceCriterion>.from(defaults.criteria);
    for (final map in maps) {
      final id = map['criterion_id'] as String;
      final existing = defaults.criteria[id];
      final criterion = PreferenceCriterion.fromMap(
        map,
        fallbackLabel: existing?.label,
        fallbackDescription: existing?.description,
      );
      updatedCriteria[id] = criterion;
    }

    return UserPreferences(criteria: updatedCriteria);
  }

  // ==========================================
  // SCAN HISTORY (SEPARATE FROM FOOD LOGS)
  // ==========================================

  /// Records a scanned product in scan history.
  Future<int> insertScanHistory(ScanHistoryEntry entry) async {
    final db = await database;
    return await db.insert('scan_history', entry.toMap());
  }

  /// Retrieves chronological scan history (newest first).
  Future<List<ScanHistoryEntry>> getScanHistory({int limit = 100}) async {
    final db = await database;
    final maps = await db.query(
      'scan_history',
      orderBy: 'scanned_at DESC',
      limit: limit,
    );
    return maps.map((m) => ScanHistoryEntry.fromMap(m)).toList();
  }

  /// Clears all entries from scan history.
  Future<int> clearScanHistory() async {
    final db = await database;
    return await db.delete('scan_history');
  }

  // ==========================================
  // CUSTOM PRODUCT LISTS
  // ==========================================

  /// Creates a new custom product list.
  Future<void> createProductList(String id, String name) async {
    final db = await database;
    await db.insert(
      'product_lists',
      {
        'id': id,
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Adds a product barcode to a custom list.
  Future<void> addProductToList(String listId, String barcode) async {
    final db = await database;
    await db.insert(
      'product_list_items',
      {
        'list_id': listId,
        'barcode': barcode,
        'added_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Removes a product barcode from a custom list.
  Future<void> removeProductFromList(String listId, String barcode) async {
    final db = await database;
    await db.delete(
      'product_list_items',
      where: 'list_id = ? AND barcode = ?',
      whereArgs: [listId, barcode],
    );
  }

  /// Retrieves all custom product lists with their contained barcodes.
  Future<List<ProductList>> getProductLists() async {
    final db = await database;
    final listMaps = await db.query('product_lists', orderBy: 'created_at ASC');
    final itemMaps = await db.query('product_list_items');

    final barcodesByList = <String, List<String>>{};
    for (final item in itemMaps) {
      final listId = item['list_id'] as String;
      final barcode = item['barcode'] as String;
      barcodesByList.putIfAbsent(listId, () => []).add(barcode);
    }

    return listMaps.map((m) {
      final id = m['id'] as String;
      return ProductList.fromMap(m, barcodes: barcodesByList[id] ?? []);
    }).toList();
  }

  /// Deletes a custom product list and its items.
  Future<void> deleteProductList(String id) async {
    final db = await database;
    await db.delete('product_list_items', where: 'list_id = ?', whereArgs: [id]);
    await db.delete('product_lists', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // PENDING CONTRIBUTIONS (OFFLINE SYNC QUEUE)
  // ==========================================

  /// Queues an offline edit/contribution for background sync to Open Food Facts.
  Future<int> queuePendingContribution(String barcode, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('pending_contributions', {
      'barcode': barcode,
      'data_json': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Retrieves all queued offline contributions.
  Future<List<Map<String, dynamic>>> getPendingContributions() async {
    final db = await database;
    return await db.query('pending_contributions', orderBy: 'created_at ASC');
  }

  /// Removes a successfully synced contribution.
  Future<int> removePendingContribution(int id) async {
    final db = await database;
    return await db.delete('pending_contributions', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // FOOD LOGS (SLICE 2)
  // ==========================================

  /// Inserts a new food log entry and returns its generated integer ID.
  Future<int> insertFoodLog(FoodLogEntry entry) async {
    final db = await database;
    return await db.insert('food_logs', entry.toMap());
  }

  /// Retrieves all food log entries for a given calendar date (defaults to today in local time).
  Future<List<FoodLogEntry>> getFoodLogsForDate([DateTime? date]) async {
    final db = await database;
    final target = date ?? DateTime.now();
    final startOfDay = DateTime(target.year, target.month, target.day).toIso8601String();
    final endOfDay = DateTime(target.year, target.month, target.day, 23, 59, 59, 999).toIso8601String();

    final result = await db.query(
      'food_logs',
      where: 'logged_at >= ? AND logged_at <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'logged_at DESC',
    );

    return result.map((map) => FoodLogEntry.fromMap(map)).toList();
  }

  /// Deletes a single food log entry by its ID.
  Future<int> deleteFoodLog(int id) async {
    final db = await database;
    return await db.delete(
      'food_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clears all food logs for a given calendar date.
  Future<int> clearFoodLogsForDate([DateTime? date]) async {
    final db = await database;
    final target = date ?? DateTime.now();
    final startOfDay = DateTime(target.year, target.month, target.day).toIso8601String();
    final endOfDay = DateTime(target.year, target.month, target.day, 23, 59, 59, 999).toIso8601String();

    return await db.delete(
      'food_logs',
      where: 'logged_at >= ? AND logged_at <= ?',
      whereArgs: [startOfDay, endOfDay],
    );
  }

  /// Retrieves all food log entries within a specific date range [start] to [end] (inclusive).
  Future<List<FoodLogEntry>> getFoodLogsForDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final startIso = DateTime(start.year, start.month, start.day).toIso8601String();
    final endIso = DateTime(end.year, end.month, end.day, 23, 59, 59, 999).toIso8601String();

    final result = await db.query(
      'food_logs',
      where: 'logged_at >= ? AND logged_at <= ?',
      whereArgs: [startIso, endIso],
      orderBy: 'logged_at DESC',
    );

    return result.map((map) => FoodLogEntry.fromMap(map)).toList();
  }

  /// Helper to retrieve food logs for the past [days] days (including today).
  Future<List<FoodLogEntry>> getFoodLogsForLastDays(int days) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days - 1));
    return getFoodLogsForDateRange(start, now);
  }

  /// Retrieves all food log entries stored in local SQLite, ordered by newest first.
  Future<List<FoodLogEntry>> getAllFoodLogs() async {
    final db = await database;
    final result = await db.query(
      'food_logs',
      orderBy: 'logged_at DESC',
    );
    return result.map((map) => FoodLogEntry.fromMap(map)).toList();
  }

  /// Clears all food log entries across all dates.
  Future<int> clearAllFoodLogs() async {
    final db = await database;
    return await db.delete('food_logs');
  }

  /// Inserts realistic sample food logs for the past 6 days for testing/demo purposes.
  Future<void> seedSampleWeekLogs() async {
    final now = DateTime.now();

    final samples = [
      FoodLogEntry(
        barcode: '8901063012134',
        name: 'Parle-G Original Gluco Biscuits',
        brand: 'Parle',
        portionLabel: '1 biscuit (x3)',
        portionAmount: 15.0,
        portionBasis: 'g',
        sugarGrams: 3.8,
        loggedAt: now.subtract(const Duration(days: 1, hours: 6)),
      ),
      FoodLogEntry(
        barcode: '8901030383458',
        name: 'Kissan Fresh Tomato Ketchup',
        brand: 'Kissan',
        portionLabel: '1 tbsp',
        portionAmount: 15.0,
        portionBasis: 'g',
        sugarGrams: 3.8,
        loggedAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      FoodLogEntry(
        barcode: '8901764012211',
        name: 'Thums Up Carbonated Drink',
        brand: 'Coca-Cola',
        portionLabel: 'Whole pack (300ml)',
        portionAmount: 300.0,
        portionBasis: 'ml',
        sugarGrams: 31.8,
        loggedAt: now.subtract(const Duration(days: 2, hours: 4)),
      ),
      FoodLogEntry(
        barcode: '8901725181222',
        name: "Haldiram's Alu Bhujia",
        brand: "Haldiram's",
        portionLabel: '1 handful (25g)',
        portionAmount: 25.0,
        portionBasis: 'g',
        sugarGrams: 0.5,
        loggedAt: now.subtract(const Duration(days: 3, hours: 5)),
      ),
      FoodLogEntry(
        barcode: '0004614504046',
        name: 'AQUAFINA',
        brand: 'Generic',
        portionLabel: '1 serving (30g)',
        portionAmount: 30.0,
        portionBasis: 'g',
        sugarGrams: null,
        loggedAt: now.subtract(const Duration(days: 3, hours: 3)),
      ),
      FoodLogEntry(
        barcode: '8901063142213',
        name: 'Britannia Good Day Butter Biscuits',
        brand: 'Britannia',
        portionLabel: '1 biscuit (x2)',
        portionAmount: 20.0,
        portionBasis: 'g',
        sugarGrams: 4.4,
        loggedAt: now.subtract(const Duration(days: 4, hours: 7)),
      ),
      FoodLogEntry(
        barcode: '8901058852233',
        name: 'Maggi 2-Minute Masala Noodles',
        brand: 'Nestle',
        portionLabel: '1 bowl (70g)',
        portionAmount: 70.0,
        portionBasis: 'g',
        sugarGrams: 2.2,
        loggedAt: now.subtract(const Duration(days: 4, hours: 2)),
      ),
      FoodLogEntry(
        barcode: '8901719102011',
        name: 'Frooti Mango Drink',
        brand: 'Parle Agro',
        portionLabel: 'Whole pack (150ml)',
        portionAmount: 150.0,
        portionBasis: 'ml',
        sugarGrams: 19.8,
        loggedAt: now.subtract(const Duration(days: 5, hours: 5)),
      ),
      FoodLogEntry(
        barcode: '7622201750244',
        name: 'Oreo Original Vanilla Creme Biscuits',
        brand: 'Cadbury',
        portionLabel: '1 biscuit (x2)',
        portionAmount: 22.8,
        portionBasis: 'g',
        sugarGrams: 8.7,
        loggedAt: now.subtract(const Duration(days: 5, hours: 1)),
      ),
      FoodLogEntry(
        barcode: '8901063012134',
        name: 'Parle-G Original Gluco Biscuits',
        brand: 'Parle',
        portionLabel: '1 biscuit (x4)',
        portionAmount: 20.0,
        portionBasis: 'g',
        sugarGrams: 5.1,
        loggedAt: now.subtract(const Duration(days: 6, hours: 4)),
      ),
    ];

    for (final entry in samples) {
      await insertFoodLog(entry);
    }
  }

  // ==========================================
  // USER SETTINGS (DAILY LIMIT)
  // ==========================================

  /// Gets the user's daily sugar limit in grams (defaults to 25.0g WHO limit).
  Future<double> getDailyLimit() async {
    final db = await database;
    final maps = await db.query(
      'user_settings',
      where: 'key = ?',
      whereArgs: ['daily_limit_g'],
    );
    if (maps.isNotEmpty) {
      final val = double.tryParse(maps.first['value'] as String);
      if (val != null && val > 0) return val;
    }
    return 25.0;
  }

  /// Sets the user's daily sugar limit in grams.
  Future<void> setDailyLimit(double limitGrams) async {
    final db = await database;
    await db.insert(
      'user_settings',
      {
        'key': 'daily_limit_g',
        'value': limitGrams.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
