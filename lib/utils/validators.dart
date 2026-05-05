/// Validator untuk form login dan register
class Validators {
  /// Regex pattern untuk validasi format email
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validasi format email yang benar
  /// 
  /// Returns [String?] - pesan error jika tidak valid, null jika valid
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Validasi password minimal 6 karakter
  /// 
  /// Returns [String?] - pesan error jika tidak valid, null jika valid
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  /// Validasi nama tidak kosong
  /// 
  /// Returns [String?] - pesan error jika tidak valid, null jika valid
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.trim().length < 2) {
      return 'Nama minimal 2 karakter';
    }
    return null;
  }

  /// Validasi konfirmasi password
  /// 
  /// [password] - password asli
  /// [confirmPassword] - konfirmasi password
  /// 
  /// Returns [String?] - pesan error jika tidak valid, null jika valid
  static String? validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (confirmPassword != password) {
      return 'Password tidak cocok';
    }
    return null;
  }

  /// Validasi password dengan aturan yang lebih ketat
  /// 
  /// - Minimal 8 karakter
  /// - Mengandung huruf besar dan kecil
  /// - Mengandung angka
  /// 
  /// Returns [String?] - pesan error jika tidak valid, null jika valid
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password harus mengandung huruf besar';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password harus mengandung huruf kecil';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password harus mengandung angka';
    }
    return null;
  }
}
