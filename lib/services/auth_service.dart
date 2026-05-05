import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart' as models;
import '../utils/constants.dart';

/// Service untuk menangani autentikasi dengan Firebase Auth
class AuthService {
  // Instance FirebaseAuth
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  /// Registrasi user baru dengan email dan password
  /// 
  /// Returns [models.User] jika berhasil
  /// Throws [FirebaseException] dengan error message jika gagal
  Future<models.User> registerWithEmail(String email, String password) async {
    try {
      // Buat user baru dengan email dan password
      final firebase_auth.UserCredential credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Dapatkan user yang baru dibuat
      final firebase_auth.User? firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw firebase_auth.FirebaseException(
          plugin: 'auth_service',
          code: 'REGISTRATION_FAILED',
          message: 'Gagal membuat user. Silakan coba lagi.',
        );
      }

      // Kirim email verifikasi
      await firebaseUser.sendEmailVerification();

      // Buat objek User model
      final now = DateTime.now();
      final user = models.User(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? email,
        displayName: firebaseUser.displayName,
        createdAt: now,
        lastLogin: now,
      );

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw firebase_auth.FirebaseException(
        plugin: 'auth_service',
        code: 'UNKNOWN_ERROR',
        message: 'Terjadi kesalahan saat registrasi: ${e.toString()}',
      );
    }
  }

  /// Login dengan email dan password
  /// 
  /// Returns [models.User] jika berhasil
  /// Throws [FirebaseException] dengan error message jika gagal
  Future<models.User> loginWithEmail(String email, String password) async {
    try {
      // Login dengan email dan password
      final firebase_auth.UserCredential credential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Dapatkan user yang login
      final firebase_auth.User? firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw firebase_auth.FirebaseException(
          plugin: 'auth_service',
          code: 'LOGIN_FAILED',
          message: 'Gagal login. Silakan coba lagi.',
        );
      }

      // Periksa apakah email sudah diverifikasi
      // Untuk demo: skip verifikasi email
      // Jika ingin wajib verifikasi, aktifkan kode di bawah ini:
      /*
      if (!firebaseUser.emailVerified) {
        // Kirim ulang email verifikasi
        await firebaseUser.sendEmailVerification();
        throw firebase_auth.FirebaseException(
          plugin: 'auth_service',
          code: 'EMAIL_NOT_VERIFIED',
          message: 'Email belum diverifikasi. Silakan cek inbox email Anda.',
        );
      }
      */

      // Ambil data user dari provider jika ada
      List<firebase_auth.UserInfo>? providerData = firebaseUser.providerData;

      // Buat objek User model
      final user = models.User(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? email,
        displayName: firebaseUser.displayName,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        lastLogin: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
      );

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw firebase_auth.FirebaseException(
        plugin: 'auth_service',
        code: 'UNKNOWN_ERROR',
        message: 'Terjadi kesalahan saat login: ${e.toString()}',
      );
    }
  }

  /// Logout user yang sedang login
  /// 
  /// Returns true jika berhasil
  /// Throws [FirebaseException] jika gagal
  Future<bool> logout() async {
    try {
      await _firebaseAuth.signOut();
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw firebase_auth.FirebaseException(
        plugin: 'auth_service',
        code: 'LOGOUT_FAILED',
        message: 'Gagal logout: ${e.toString()}',
      );
    }
  }

  /// Mendapatkan user yang sedang login
  /// 
  /// Returns [models.User] jika ada user yang login
  /// Returns null jika tidak ada user yang login
  models.User? getCurrentUser() {
    try {
      final firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        return null;
      }

      // Buat objek User model
      final user = models.User(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoURL: firebaseUser.photoURL,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        lastLogin: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
      );

      return user;
    } catch (e) {
      return null;
    }
  }

  /// Reset password dengan mengirim email reset ke email yang diberikan
  /// 
  /// Returns true jika email berhasil dikirim
  /// Throws [FirebaseException] jika gagal
  Future<bool> resetPassword(String email) async {
    try {
      // Langsung kirim email reset password
      // Firebase akan menangani jika email tidak terdaftar
      await _firebaseAuth.sendPasswordResetEmail(email: email);

      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw firebase_auth.FirebaseException(
        plugin: 'auth_service',
        code: 'RESET_PASSWORD_FAILED',
        message: 'Gagal mengirim email reset password: ${e.toString()}',
      );
    }
  }

  /// Update display name user yang sedang login
  /// 
  /// Returns true jika berhasil
  /// Throws [FirebaseException] jika gagal
  Future<bool> updateDisplayName(String displayName) async {
    try {
      final firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;
      
      if (firebaseUser == null) {
        throw firebase_auth.FirebaseException(
          plugin: 'auth_service',
          code: 'NO_USER',
          message: 'Tidak ada user yang login.',
        );
      }

      await firebaseUser.updateDisplayName(displayName);
      
      // Refresh user untuk mendapatkan data terbaru
      await firebaseUser.reload();
      
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw firebase_auth.FirebaseException(
        plugin: 'auth_service',
        code: 'UPDATE_DISPLAY_NAME_FAILED',
        message: 'Gagal memperbarui nama: ${e.toString()}',
      );
    }
  }

  /// Update email user yang sedang login
  /// 
  /// Returns true jika berhasil
  /// Throws [FirebaseException] jika gagal
  Future<bool> updateEmail(String email) async {
    try {
      final firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;
      
      if (firebaseUser == null) {
        throw firebase_auth.FirebaseException(
          plugin: 'auth_service',
          code: 'NO_USER',
          message: 'Tidak ada user yang login.',
        );
      }

      await firebaseUser.updateEmail(email);
      
      // Refresh user untuk mendapatkan data terbaru
      await firebaseUser.reload();
      
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw firebase_auth.FirebaseException(
        plugin: 'auth_service',
        code: 'UPDATE_EMAIL_FAILED',
        message: 'Gagal memperbarui email: ${e.toString()}',
      );
    }
  }

  /// Update password user yang sedang login
  /// 
  /// Returns true jika berhasil
  /// Throws [FirebaseException] jika gagal
  Future<bool> updatePassword(String password) async {
    try {
      final firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;
      
      if (firebaseUser == null) {
        throw firebase_auth.FirebaseException(
          plugin: 'auth_service',
          code: 'NO_USER',
          message: 'Tidak ada user yang login.',
        );
      }

      await firebaseUser.updatePassword(password);
      
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw firebase_auth.FirebaseException(
        plugin: 'auth_service',
        code: 'UPDATE_PASSWORD_FAILED',
        message: 'Gagal memperbarui password: ${e.toString()}',
      );
    }
  }

  /// Update photo URL user yang sedang login
  /// 
  /// Foto disimpan secara lokal di device (tidak perlu Firebase Storage)
  /// Returns path foto jika berhasil
  /// Throws [FirebaseException] jika gagal
  Future<String> updateProfilePhoto(String imagePath) async {
    try {
      final firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;
      
      if (firebaseUser == null) {
        throw firebase_auth.FirebaseException(
          plugin: 'auth_service',
          code: 'NO_USER',
          message: 'Tidak ada user yang login.',
        );
      }

      // Langsung gunakan path dari image picker
      // Foto akan tersimpan di direktori cache image picker
      developer.log('AuthService: Profile photo path: $imagePath', name: 'AuthService');
      
      // Return langsung path yang diberikan image picker
      return imagePath;
    } catch (e) {
      developer.log('AuthService: Error saving profile photo: $e', name: 'AuthService', error: e);
      throw firebase_auth.FirebaseException(
        plugin: 'auth_service',
        code: 'UPDATE_PHOTO_FAILED',
        message: 'Gagal memperbarui foto: ${e.toString()}',
      );
    }
  }

  /// Handle FirebaseAuthException dan kembalikan pesan error yang jelas
  firebase_auth.FirebaseException _handleAuthException(
    firebase_auth.FirebaseAuthException e,
  ) {
    String message;
    String code = e.code;

    switch (code) {
      // Error terkait email
      case 'invalid-email':
        message = 'Format email tidak valid.';
        break;
      case 'email-already-in-use':
        message = 'Email sudah terdaftar. Silakan gunakan email lain.';
        break;
      case 'user-not-found':
        message = 'Email tidak terdaftar.';
        break;
      case 'user-disabled':
        message = 'Akun Anda telah dinonaktifkan.';
        break;
      case 'wrong-password':
        message = 'Password yang Anda masukkan salah.';
        break;
      case 'requires-recent-login':
        message = 'Silakan login ulang untuk melanjutkan.';
        break;

      // Error terkait password
      case 'weak-password':
        message = 'Password terlalu lemah. Gunakan minimal 6 karakter.';
        break;
      case 'password-does-not-meet-requirements':
        message = 'Password tidak memenuhi persyaratan keamanan.';
        break;
      case 'too-many-requests':
        message = 'Terlalu banyak percobaan. Silakan coba lagi nanti.';
        break;
      case 'network-request-failed':
        message = 'Tidak ada koneksi internet. Periksa koneksi Anda.';
        break;
      case 'operation-not-allowed':
        message = 'Operasi tidak diizinkan.';
        break;
      case 'invalid-credential':
        message = 'Kredensial tidak valid.';
        break;
      case 'credential-already-in-use':
        message = 'Kredensial ini sudah digunakan oleh akun lain.';
        break;

      // Default error
      default:
        message = e.message ?? 'Terjadi kesalahan. Silakan coba lagi.';
    }

    return firebase_auth.FirebaseException(
      plugin: 'auth_service',
      code: code,
      message: message,
    );
  }

  /// Stream untuk mendengarkan perubahan status autentikasi
  Stream<models.User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) {
        return null;
      }

      return models.User(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        lastLogin: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
      );
    });
  }
}
