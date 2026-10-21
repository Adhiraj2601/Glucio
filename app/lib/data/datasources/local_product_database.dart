import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/food_log_entry.dart';
import '../models/portion.dart';
import '../models/product.dart';

/// Local SQLite database managing user-added products, food logs, and user settings.
class LocalProductDatabase {
  static final LocalProductDatabase instance = LocalProductDatabase._init();
  static Database? _database;

  LocalProductDatabase._init();

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
      version: 2,
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createV2Tables(db);
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
      );
    }
    return null;
  }

  /// Returns all user-added products.
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('user_products', orderBy: 'created_at DESC');
    return maps.map((row) {
      List<Portion> portions = [];
      if (row['portions_json'] != null) {
        try {
          final list = jsonDecode(row['portions_json'] as String) as List<dynamic>;
          portions = list
              .map((item) => Portion.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }

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
      );
    }).toList();
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
      // 1 day ago (Yesterday) - Moderate (within limit)
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

      // 2 days ago - High Sugar Day (Exceeded 25g limit)
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

      // 3 days ago - Low Sugar / Healthy
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
        sugarGrams: null, // Unknown sugar test
        loggedAt: now.subtract(const Duration(days: 3, hours: 3)),
      ),

      // 4 days ago - Biscuits & Tea
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

      // 5 days ago - High sugar treat
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

      // 6 days ago - Moderate
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
