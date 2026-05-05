import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/transaction.dart' as models;
import '../models/category.dart' as category_models;
import '../services/firebase_service.dart';
import '../services/auth_service.dart';

/// DatabaseHelper yang menggunakan Firebase Firestore untuk sinkronisasi data antar device
class DatabaseHelper {
  static const String tableName = 'transactions';
  static const String categoryTableName = 'categories';

  // Firebase Service instance
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();

  // Current user UID - null jika belum login
  String? _currentUid;

  /// Set user UID secara manual (dipanggil setelah login)
  void setCurrentUser(String uid) {
    _currentUid = uid;
    developer.log('DB: User UID set to: $uid', name: 'DatabaseHelper');
  }

  /// Dapatkan user UID saat ini
  String? get currentUid {
    if (_currentUid != null) return _currentUid;

    // ✅ Coba ambil langsung dari FirebaseAuth (sudah pasti ada setelah login)
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      _currentUid = firebaseUser.uid;
      developer.log('DB: Got UID from FirebaseAuth: $_currentUid', name: 'DatabaseHelper');
      return _currentUid;
    }

    // Fallback ke AuthService
    final user = _authService.getCurrentUser();
    if (user != null) {
      _currentUid = user.uid;
      return _currentUid;
    }

    developer.log('DB: No user logged in', name: 'DatabaseHelper');
    return null;
  }

  // ============ TRANSAKSI - Menggunakan Firebase Firestore ============

  /// Cek apakah user sudah login (untuk menggunakan Firestore)
  bool get _isUserLoggedIn => currentUid != null;

  // Insert transaksi ke Firestore
  Future<int> insertTransaction(models.Transaction transaction) async {
    if (!_isUserLoggedIn) {
      developer.log('DB: User not logged in, cannot save transaction', name: 'DatabaseHelper');
      throw Exception('User must be logged in to save transactions');
    }

    developer.log('DB: Saving transaction to Firestore for user: $currentUid', name: 'DatabaseHelper');
    final transactionData = {
      'description': transaction.description,
      'amount': transaction.amount,
      'category': transaction.category,
      'type': transaction.type,
      'date': transaction.date.toIso8601String(),
    };
    final docId = await _firebaseService.saveTransaction(currentUid!, transactionData);
    developer.log('DB: Transaction saved to Firestore with ID: $docId', name: 'DatabaseHelper');
    return 1;
  }

  // Get all transactions dari Firestore
  Future<List<models.Transaction>> getAllTransactions() async {
    if (!_isUserLoggedIn) {
      developer.log('DB: User not logged in, returning empty list', name: 'DatabaseHelper');
      return [];
    }

    developer.log('DB: Fetching all transactions from Firestore for user: $currentUid', name: 'DatabaseHelper');
    final maps = await _firebaseService.getTransactions(currentUid!);
    developer.log('DB: Found ${maps.length} transactions from Firestore', name: 'DatabaseHelper');
    return maps.map((m) => models.Transaction.fromMap(m)).toList();
  }

  // Update transaksi di Firestore
  Future<int> updateTransaction(models.Transaction transaction) async {
    if (!_isUserLoggedIn || transaction.id == null) {
      developer.log('DB: Cannot update transaction - user not logged in or no ID', name: 'DatabaseHelper');
      throw Exception('User must be logged in to update transactions');
    }

    developer.log('DB: Updating transaction in Firestore: ${transaction.id}', name: 'DatabaseHelper');
    final transactionData = {
      'description': transaction.description,
      'amount': transaction.amount,
      'category': transaction.category,
      'type': transaction.type,
      'date': transaction.date.toIso8601String(),
    };
    await _firebaseService.updateTransaction(currentUid!, transaction.id.toString(), transactionData);
    return 1;
  }

  // Delete transaksi dari Firestore
  Future<int> deleteTransaction(dynamic id) async {
    if (!_isUserLoggedIn) {
      developer.log('DB: Cannot delete transaction - user not logged in', name: 'DatabaseHelper');
      throw Exception('User must be logged in to delete transactions');
    }

    developer.log('DB: Deleting transaction from Firestore: $id', name: 'DatabaseHelper');
    await _firebaseService.deleteTransaction(currentUid!, id.toString());
    return 1;
  }

  // Get transactions by month dari Firestore
  Future<List<models.Transaction>> getTransactionsByMonth(int month, int year) async {
    if (!_isUserLoggedIn) {
      developer.log('DB: User not logged in, returning empty list', name: 'DatabaseHelper');
      return [];
    }

    developer.log('DB: Fetching transactions for month=$month, year=$year from Firestore', name: 'DatabaseHelper');
    final maps = await _firebaseService.getTransactionsByMonth(currentUid!, month, year);
    developer.log('DB: Found ${maps.length} transactions from Firestore', name: 'DatabaseHelper');
    return maps.map((m) => models.Transaction.fromMap(m)).toList();
  }

  // Get total income & expense dari Firestore
  Future<Map<String, double>> getTotalByType(int month, int year) async {
    if (!_isUserLoggedIn) {
      developer.log('DB: User not logged in, returning zero totals', name: 'DatabaseHelper');
      return {'income': 0.0, 'expense': 0.0};
    }

    developer.log('DB: Computing totals from Firestore for user: $currentUid', name: 'DatabaseHelper');
    final totals = await _firebaseService.getTotalByType(currentUid!, month, year);
    developer.log('DB: Totals from Firestore - income: ${totals['income']}, expense: ${totals['expense']}', name: 'DatabaseHelper');
    return totals;
  }

  // Get total by category dari Firestore
  Future<Map<String, double>> getTotalByCategory(int month, int year) async {
    if (!_isUserLoggedIn) {
      return {};
    }

    final transactions = await _firebaseService.getTransactionsByMonth(currentUid!, month, year);
    final Map<String, double> totals = {};
    for (var transaction in transactions) {
      final category = transaction['category'] as String;
      final amount = (transaction['amount'] is num)
          ? (transaction['amount'] as num).toDouble()
          : double.tryParse(transaction['amount'].toString()) ?? 0.0;
      totals[category] = (totals[category] ?? 0) + amount;
    }
    return totals;
  }

  // ============ KATEGORI - Menggunakan Firebase Firestore ============

  // Insert kategori ke Firestore
  Future<int> insertCategory(category_models.Category category) async {
    if (!_isUserLoggedIn) {
      throw Exception('User must be logged in to save categories');
    }

    developer.log('DB: Saving category to Firestore for user: $currentUid', name: 'DatabaseHelper');
    final categoryData = {
      'name': category.name,
      'type': category.type,
      'icon': category.icon,
      'color': category.color,
    };
    final docId = await _firebaseService.saveCategory(currentUid!, categoryData);
    developer.log('DB: Category saved to Firestore with ID: $docId', name: 'DatabaseHelper');
    return 1;
  }

  // Get all categories dari Firestore
  Future<List<category_models.Category>> getAllCategories() async {
    if (!_isUserLoggedIn) {
      developer.log('DB: User not logged in, returning default categories', name: 'DatabaseHelper');
      return _getDefaultCategories();
    }

    try {
      developer.log('DB: Fetching categories from Firestore for user: $currentUid', name: 'DatabaseHelper');
      final maps = await _firebaseService.getCategories(currentUid!);
      if (maps.isEmpty) {
        return _getDefaultCategories();
      }
      return maps.map((m) => category_models.Category.fromMap(m)).toList();
    } catch (e) {
      developer.log('DB: Error fetching categories: $e', name: 'DatabaseHelper');
      return _getDefaultCategories();
    }
  }

  // Get categories by type
  Future<List<category_models.Category>> getCategoriesByType(String type) async {
    final allCategories = await getAllCategories();
    return allCategories.where((c) => c.type == type).toList();
  }

  // Update kategori di Firestore
  Future<int> updateCategory(category_models.Category category) async {
    if (!_isUserLoggedIn || category.id == null) {
      throw Exception('User must be logged in to update categories');
    }

    developer.log('DB: Updating category in Firestore: ${category.id}', name: 'DatabaseHelper');
    final categoryData = {
      'name': category.name,
      'type': category.type,
      'icon': category.icon,
      'color': category.color,
    };
    await _firebaseService.updateCategory(currentUid!, category.id.toString(), categoryData);
    return 1;
  }

  // Delete kategori dari Firestore
  Future<int> deleteCategory(dynamic id) async {
    if (!_isUserLoggedIn) {
      throw Exception('User must be logged in to delete categories');
    }

    developer.log('DB: Deleting category from Firestore: $id', name: 'DatabaseHelper');
    await _firebaseService.deleteCategory(currentUid!, id.toString());
    return 1;
  }

  // Default categories
  List<category_models.Category> _getDefaultCategories() {
    return [
      category_models.Category(id: 1, name: 'Gaji', type: 'income', icon: 'account_balance_wallet', color: 0xFF4CAF50),
      category_models.Category(id: 2, name: 'Investasi', type: 'income', icon: 'trending_up', color: 0xFF8BC34A),
      category_models.Category(id: 3, name: 'Freelance', type: 'income', icon: 'laptop', color: 0xFF009688),
      category_models.Category(id: 4, name: 'Lainnya', type: 'income', icon: 'more_horiz', color: 0xFF607D8B),
      category_models.Category(id: 5, name: 'Makanan', type: 'expense', icon: 'restaurant', color: 0xFFFF5722),
      category_models.Category(id: 6, name: 'Transportasi', type: 'expense', icon: 'directions_car', color: 0xFF2196F3),
      category_models.Category(id: 7, name: 'Belanja', type: 'expense', icon: 'shopping_cart', color: 0xFFE91E63),
      category_models.Category(id: 8, name: 'Tagihan', type: 'expense', icon: 'receipt', color: 0xFF9C27B0),
      category_models.Category(id: 9, name: 'Hiburan', type: 'expense', icon: 'movie', color: 0xFFFF9800),
      category_models.Category(id: 10, name: 'Kesehatan', type: 'expense', icon: 'local_hospital', color: 0xFFF44336),
    ];
  }
}