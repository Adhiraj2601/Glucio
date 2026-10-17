import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/portion.dart';
import '../models/product.dart';

/// Local SQLite database managing user-added and custom-edited products.
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
      version: 1,
      onCreate: _createDB,
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
  }

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
    // TODO(Slice-5): Sync user-contributed product to Supabase cloud database
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
}
