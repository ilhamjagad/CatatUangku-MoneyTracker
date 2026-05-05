import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../utils/constants.dart';

/// Service untuk menangani operasi database cloud (Firestore)
class FirebaseService {
  // Instance FirebaseFirestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Membuat document user di Firestore
  /// 
  /// [user] - Objek User yang akan disimpan
  /// Returns true jika berhasil
  /// Throws [FirebaseException] jika gagal
  Future<bool> createUserDocument(User user) async {
    try {
      // Buat document dengan UID sebagai ID document
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(user.toJson());
      return true;
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'CREATE_USER_FAILED',
        message: 'Gagal membuat data user: ${e.toString()}',
      );
    }
  }

  /// Mendapatkan data user dari Firestore
  /// 
  /// [uid] - UID user yang akan diambil
  /// Returns [User] jika ditemukan
  /// Throws [FirebaseException] jika gagal
  Future<User?> getUserDocument(String uid) async {
    try {
      // Ambil document berdasarkan UID
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(uid)
              .get();

      // Jika document tidak ada
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return null;
      }

      // Parse data ke objek User
      return User.fromJson(docSnapshot.data()!);
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'GET_USER_FAILED',
        message: 'Gagal mengambil data user: ${e.toString()}',
      );
    }
  }

  /// Update last login user
  /// 
  /// [uid] - UID user yang akan diupdate
  /// Returns true jika berhasil
  /// Throws [FirebaseException] jika gagal
  Future<bool> updateUserLastLogin(String uid) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'lastLogin': DateTime.now().toIso8601String(),
      });
      return true;
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'UPDATE_LAST_LOGIN_FAILED',
        message: 'Gagal update last login: ${e.toString()}',
      );
    }
  }

  // ==================== METODE TRANSAKSI ====================

  /// Simpan transaksi ke cloud
  /// 
  /// [uid] - UID user
  /// [transactionData] - Data transaksi dalam bentuk Map
  /// Returns ID transaksi yang dibuat
  /// Throws [FirebaseException] jika gagal
  Future<String> saveTransaction(
    String uid,
    Map<String, dynamic> transactionData,
  ) async {
    try {
      // Tambahkan timestamp
      final dataWithTimestamp = {
        ...transactionData,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Simpan ke sub-collection transactions
      DocumentReference docRef = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.transactionsCollection)
          .add(dataWithTimestamp);

      return docRef.id;
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'SAVE_TRANSACTION_FAILED',
        message: 'Gagal menyimpan transaksi: ${e.toString()}',
      );
    }
  }

  /// Ambil semua transaksi user dari cloud
  /// 
  /// [uid] - UID user
  /// Returns List<Map<String, dynamic>> berisi data transaksi
  /// Throws [FirebaseException] jika gagal
  Future<List<Map<String, dynamic>>> getTransactions(String uid) async {
    try {
      // Ambil semua dokumen dari sub-collection transactions
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.transactionsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      // Parse data ke List
      List<Map<String, dynamic>> transactions = [];
      for (var doc in querySnapshot.docs) {
        transactions.add({
          'id': doc.id,
          ...doc.data(),
        });
      }

      return transactions;
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'GET_TRANSACTIONS_FAILED',
        message: 'Gagal mengambil transaksi: ${e.toString()}',
      );
    }
  }

  /// Ambil transaksi user berdasarkan bulan dan tahun
  /// 
  /// [uid] - UID user
  /// [month] - Bulan (1-12)
  /// [year] - Tahun
  /// Returns List<Map<String, dynamic>> berisi data transaksi
  /// Throws [FirebaseException] jika gagal
  Future<List<Map<String, dynamic>>> getTransactionsByMonth(
    String uid,
    int month,
    int year,
  ) async {
    try {
      // Hitung tanggal awal dan akhir bulan
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      // Ambil dokumen dari sub-collection transactions dengan filter tanggal
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.transactionsCollection)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      // Parse data ke List
      List<Map<String, dynamic>> transactions = [];
      for (var doc in querySnapshot.docs) {
        transactions.add({
          'id': doc.id,
          ...doc.data(),
        });
      }

      return transactions;
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'GET_TRANSACTIONS_BY_MONTH_FAILED',
        message: 'Gagal mengambil transaksi per bulan: ${e.toString()}',
      );
    }
  }

  /// Hitung total income dan expense berdasarkan bulan dan tahun
  /// 
  /// [uid] - UID user
  /// [month] - Bulan (1-12)
  /// [year] - Tahun
  /// Returns Map<String, double> dengan keys 'income' dan 'expense'
  /// Throws [FirebaseException] jika gagal
  Future<Map<String, double>> getTotalByType(
    String uid,
    int month,
    int year,
  ) async {
    try {
      final transactions = await getTransactionsByMonth(uid, month, year);
      
      double income = 0;
      double expense = 0;
      
      for (var transaction in transactions) {
        final type = transaction['type'] as String?;
        final amount = (transaction['amount'] is num) 
            ? (transaction['amount'] as num).toDouble() 
            : double.tryParse(transaction['amount'].toString()) ?? 0;
        
        if (type == 'income') {
          income += amount;
        } else if (type == 'expense') {
          expense += amount;
        }
      }
      
      return {'income': income, 'expense': expense};
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'GET_TOTAL_BY_TYPE_FAILED',
        message: 'Gagal menghitung total: ${e.toString()}',
      );
    }
  }

  /// Hapus transaksi dari cloud
  /// 
  /// [uid] - UID user
  /// [transactionId] - ID transaksi yang akan dihapus
  /// Returns true jika berhasil
  /// Throws [FirebaseException] jika gagal
  Future<bool> deleteTransaction(String uid, String transactionId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.transactionsCollection)
          .doc(transactionId)
          .delete();

      return true;
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'DELETE_TRANSACTION_FAILED',
        message: 'Gagal menghapus transaksi: ${e.toString()}',
      );
    }
  }

  /// Update transaksi di cloud
  /// 
  /// [uid] - UID user
  /// [transactionId] - ID transaksi yang akan diupdate
  /// [transactionData] - Data transaksi baru
  /// Returns true jika berhasil
  /// Throws [FirebaseException] jika gagal
  Future<bool> updateTransaction(
    String uid,
    String transactionId,
    Map<String, dynamic> transactionData,
  ) async {
    try {
      final dataWithTimestamp = {
        ...transactionData,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.transactionsCollection)
          .doc(transactionId)
          .update(dataWithTimestamp);

      return true;
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'UPDATE_TRANSACTION_FAILED',
        message: 'Gagal update transaksi: ${e.toString()}',
      );
    }
  }

  // ==================== METODE KATEGORI ====================

  /// Simpan kategori ke cloud
  /// 
  /// [uid] - UID user
  /// [categoryData] - Data kategori dalam bentuk Map
  /// Returns ID kategori yang dibuat
  /// Throws [FirebaseException] jika gagal
  Future<String> saveCategory(
    String uid,
    Map<String, dynamic> categoryData,
  ) async {
    try {
      // Tambahkan timestamp
      final dataWithTimestamp = {
        ...categoryData,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Simpan ke sub-collection categories
      DocumentReference docRef = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.categoriesCollection)
          .add(dataWithTimestamp);

      return docRef.id;
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'SAVE_CATEGORY_FAILED',
        message: 'Gagal menyimpan kategori: ${e.toString()}',
      );
    }
  }

  /// Ambil semua kategori user dari cloud
  /// 
  /// [uid] - UID user
  /// Returns List<Map<String, dynamic>> berisi data kategori
  /// Throws [FirebaseException] jika gagal
  Future<List<Map<String, dynamic>>> getCategories(String uid) async {
    try {
      // Ambil semua dokumen dari sub-collection categories
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.categoriesCollection)
          .orderBy('createdAt', descending: true)
          .get();

      // Parse data ke List
      List<Map<String, dynamic>> categories = [];
      for (var doc in querySnapshot.docs) {
        categories.add({
          'id': doc.id,
          ...doc.data(),
        });
      }

      return categories;
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'GET_CATEGORIES_FAILED',
        message: 'Gagal mengambil kategori: ${e.toString()}',
      );
    }
  }

  /// Hapus kategori dari cloud
  /// 
  /// [uid] - UID user
  /// [categoryId] - ID kategori yang akan dihapus
  /// Returns true jika berhasil
  /// Throws [FirebaseException] jika gagal
  Future<bool> deleteCategory(String uid, String categoryId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.categoriesCollection)
          .doc(categoryId)
          .delete();

      return true;
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'DELETE_CATEGORY_FAILED',
        message: 'Gagal menghapus kategori: ${e.toString()}',
      );
    }
  }

  /// Update kategori di cloud
  /// 
  /// [uid] - UID user
  /// [categoryId] - ID kategori yang akan diupdate
  /// [categoryData] - Data kategori baru
  /// Returns true jika berhasil
  /// Throws [FirebaseException] jika gagal
  Future<bool> updateCategory(
    String uid,
    String categoryId,
    Map<String, dynamic> categoryData,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.categoriesCollection)
          .doc(categoryId)
          .update(categoryData);

      return true;
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_service',
        code: 'UPDATE_CATEGORY_FAILED',
        message: 'Gagal update kategori: ${e.toString()}',
      );
    }
  }

  // ==================== HELPER METHODS ====================

  /// Handle FirebaseException dan kembalikan pesan error yang jelas
  FirebaseException _handleFirestoreException(FirebaseException e) {
    String message;
    String code = e.code;

    switch (code) {
      // Error terkait permission
      case 'permission-denied':
        message = 'Anda tidak memiliki izin untuk melakukan operasi ini.';
        break;
      case 'unauthenticated':
        message = 'Silakan login terlebih dahulu.';
        break;

      // Error terkait resource
      case 'not-found':
        message = 'Data tidak ditemukan.';
        break;
      case 'already-exists':
        message = 'Data sudah ada.';
        break;

      // Error terkait quota
      case 'quota-exceeded':
        message = 'Kuota aplikasi telah habis.';
        break;

      // Error jaringan
      case 'network-request-failed':
        message = 'Tidak ada koneksi internet. Periksa koneksi Anda.';
        break;

      // Error operation
      case 'cancelled':
        message = 'Operasi dibatalkan.';
        break;
      case 'unknown':
        message = 'Terjadi kesalahan yang tidak diketahui.';
        break;
      case 'deadline-exceeded':
        message = 'Waktu habis. Silakan coba lagi.';
        break;
      case 'invalid-argument':
        message = 'Argumen tidak valid.';
        break;
      case 'internal':
        message = 'Terjadi kesalahan internal.';
        break;

      // Default error
      default:
        message = e.message ?? 'Terjadi kesalahan. Silakan coba lagi.';
    }

    return FirebaseException(
      plugin: 'firebase_service',
      code: code,
      message: message,
    );
  }

  // ==================== STREAM METHODS ====================

  /// Stream untuk mendengarkan perubahan transaksi
  Stream<List<Map<String, dynamic>>> watchTransactions(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.transactionsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      List<Map<String, dynamic>> transactions = [];
      for (var doc in snapshot.docs) {
        transactions.add({
          'id': doc.id,
          ...doc.data(),
        });
      }
      return transactions;
    });
  }

  /// Stream untuk mendengarkan perubahan kategori
  Stream<List<Map<String, dynamic>>> watchCategories(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.categoriesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      List<Map<String, dynamic>> categories = [];
      for (var doc in snapshot.docs) {
        categories.add({
          'id': doc.id,
          ...doc.data(),
        });
      }
      return categories;
    });
  }
}
