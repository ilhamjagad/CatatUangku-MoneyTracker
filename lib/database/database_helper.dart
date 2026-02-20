import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' if (dart.library.html) 'package:sqflite_common_ffi_web/sqflite_common_ffi_web.dart' as sqflite_ffi;
import '../models/transaction.dart' as models;
import '../models/category.dart' as category_models;

class DatabaseHelper {
  static const String tableName = 'transactions';
  static const String categoryTableName = 'categories';
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      developer.log('DB: Initializing database...', name: 'DatabaseHelper');
      
      final dbPath = await getDatabasesPath();
      developer.log('DB: Database path: $dbPath', name: 'DatabaseHelper');
      
      String path = join(dbPath, 'money_tracker.db');

      // Only use FFI on desktop platforms
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqflite_ffi.sqfliteFfiInit();
        final factory = sqflite_ffi.databaseFactoryFfi;
        return factory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 2,
            onCreate: _createDatabase,
            onUpgrade: _onUpgradeDatabase,
          ),
        );
      }

      return openDatabase(
        path,
        version: 2,
        onCreate: _createDatabase,
        onUpgrade: _onUpgradeDatabase,
      );
    } catch (e, stackTrace) {
      developer.log('DB: Error initializing database: $e', name: 'DatabaseHelper', error: e, stackTrace: stackTrace);
      // Return an in-memory database as fallback to prevent crash
      return openDatabase(
        ':memory:',
        version: 1,
        onCreate: _createDatabase,
      );
    }
  }

  Future<void> _onUpgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Check if categories table exists
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='$categoryTableName'");
    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE $categoryTableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          icon TEXT NOT NULL,
          color INTEGER NOT NULL
        )
      ''');
      await _insertDefaultCategories(db);
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $categoryTableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    // Insert default categories
    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      {'name': 'Gaji', 'type': 'income', 'icon': 'account_balance_wallet', 'color': 0xFF4CAF50},
      {'name': 'Investasi', 'type': 'income', 'icon': 'trending_up', 'color': 0xFF8BC34A},
      {'name': 'Freelance', 'type': 'income', 'icon': 'laptop', 'color': 0xFF009688},
      {'name': 'Lainnya', 'type': 'income', 'icon': 'more_horiz', 'color': 0xFF607D8B},
      {'name': 'Makanan', 'type': 'expense', 'icon': 'restaurant', 'color': 0xFFFF5722},
      {'name': 'Transportasi', 'type': 'expense', 'icon': 'directions_car', 'color': 0xFF2196F3},
      {'name': 'Belanja', 'type': 'expense', 'icon': 'shopping_cart', 'color': 0xFFE91E63},
      {'name': 'Tagihan', 'type': 'expense', 'icon': 'receipt', 'color': 0xFF9C27B0},
      {'name': 'Hiburan', 'type': 'expense', 'icon': 'movie', 'color': 0xFFFF9800},
      {'name': 'Kesehatan', 'type': 'expense', 'icon': 'local_hospital', 'color': 0xFFF44336},
    ];

    for (var cat in defaultCategories) {
      await db.insert(categoryTableName, cat);
    }
  }

  // Insert
  Future<int> insertTransaction(models.Transaction transaction) async {
    final db = await database;
    return db.insert(tableName, transaction.toMap());
  }

  // Get all
  Future<List<models.Transaction>> getAllTransactions() async {
    developer.log('DB: Fetching all transactions...', name: 'DatabaseHelper');
    final db = await database;
    final maps = await db.query(tableName, orderBy: 'date DESC');
    developer.log('DB: Found ${maps.length} transactions', name: 'DatabaseHelper');
    return maps.map((m) => models.Transaction.fromMap(m)).toList();
  }

  // Update
  Future<int> updateTransaction(models.Transaction transaction) async {
    final db = await database;
    return db.update(
      tableName,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // Delete
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Get transactions by month (optimized with SQL WHERE clause)
  Future<List<models.Transaction>> getTransactionsByMonth(int month, int year) async {
    developer.log('DB: Fetching transactions for month=$month, year=$year', name: 'DatabaseHelper');
    final db = await database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    
    // Filter directly at SQL level for better performance
    final maps = await db.query(
      tableName,
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    developer.log('DB: Found ${maps.length} transactions for the month', name: 'DatabaseHelper');
    return maps.map((m) => models.Transaction.fromMap(m)).toList();
  }

  // Get total income & expense (optimized with SQL aggregation)
  Future<Map<String, double>> getTotalByType(int month, int year) async {
    developer.log('DB: Computing totals for month=$month, year=$year', name: 'DatabaseHelper');
    final db = await database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    
    final result = await db.rawQuery('''
      SELECT type, SUM(amount) as total
      FROM $tableName
      WHERE date >= ? AND date <= ?
      GROUP BY type
    ''', [start.toIso8601String(), end.toIso8601String()]);
    
    double income = 0, expense = 0;
    for (var row in result) {
      final type = row['type'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      if (type == 'income') {
        income = total;
      } else {
        expense = total;
      }
    }
    developer.log('DB: Totals - income: $income, expense: $expense', name: 'DatabaseHelper');
    return {'income': income, 'expense': expense};
  }

  // Get total by category (SQL langsung)
  Future<Map<String, double>> getTotalByCategory(int month, int year) async {
    final db = await database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);

    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM $tableName
      WHERE date BETWEEN ? AND ?
      GROUP BY category
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final Map<String, double> totals = {};
    for (var row in result) {
      final category = row['category'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      totals[category] = total;
    }
    return totals;
  }

  // ============ CATEGORY CRUD ============

  // Insert category
  Future<int> insertCategory(category_models.Category category) async {
    final db = await database;
    return db.insert(categoryTableName, category.toMap());
  }

  // Get all categories
  Future<List<category_models.Category>> getAllCategories() async {
    final db = await database;
    final maps = await db.query(categoryTableName, orderBy: 'type ASC, name ASC');
    return maps.map((m) => category_models.Category.fromMap(m)).toList();
  }

  // Get categories by type
  Future<List<category_models.Category>> getCategoriesByType(String type) async {
    final db = await database;
    final maps = await db.query(
      categoryTableName,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );
    return maps.map((m) => category_models.Category.fromMap(m)).toList();
  }

  // Update category
  Future<int> updateCategory(category_models.Category category) async {
    final db = await database;
    return db.update(
      categoryTableName,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // Delete category
  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete(categoryTableName, where: 'id = ?', whereArgs: [id]);
  }
}