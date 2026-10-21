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
