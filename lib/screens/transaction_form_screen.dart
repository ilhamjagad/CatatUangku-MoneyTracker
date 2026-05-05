import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart' as models;

// Modern blue gradient color palette
class AppColors {
  static const Color primaryStart = Color(0xFF0D47A1); // Dark Blue
  static const Color primaryEnd = Color(0xFF1565C0); // Blue
  static const Color primary = Color(0xFF1565C0); // Blue as main primary
  static const Color income = Color(0xFF10B981); // Emerald green
  static const Color expense = Color(0xFFEF4444); // Modern red
  static const Color background = Color(0xFFF0F7FF); // Light blue
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE3F2FD); // Very light blue
  static const Color textPrimary = Color(0xFF0D47A1); // Dark blue
  static const Color textSecondary = Color(0xFF1565C0); // Blue
  static const Color textMuted = Color(0xFF64B5F6); // Light blue
  static const Color border = Color(0xFF1565C0); // Will be used with opacity in places
  static const Color shadow = Color(0xFF0D47A1);

  // Helper for gradient
  static LinearGradient get primaryGradient {
    return const LinearGradient(
      colors: [primaryStart, primaryEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

// Helper function untuk format currency
String formatCurrency(double amount) {
  final formatter = NumberFormat("#,##0", "id_ID");
  return formatter.format(amount);
}

// Fungsi manual untuk format angka dengan titik
String _formatWithDots(String number) {
  // Balik angka, tambahkan titik setiap 3 karakter, lalu balik kembali
  String reversed = number.split('').reversed.join();
  String withDots = reversed.replaceAllMapped(
    RegExp(r'.{3}'),
    (match) => '${match.group(0)}.'
  );
  // Hapus titik di akhir jika ada
  if (withDots.endsWith('.')) {
    withDots = withDots.substring(0, withDots.length - 1);
  }
  // Balik kembali ke normal
  return withDots.split('').reversed.join();
}

// Custom formatter untuk titik pemisah ribuan
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final String text = newValue.text;
    
    // Cek jika ada titik desimal (hanya boleh satu di akhir)
    final int dotCount = '.'.allMatches(text).length;
    
    String integerPart;
    String? decimalPart;
    
    if (dotCount > 1) {
      // Ada multiple dots - kemungkinan besar dari ribuan separator
      // Hapus semua titik dulu, lalu format ulang
      String cleanText = text.replaceAll('.', '');
      integerPart = cleanText;
      decimalPart = null;
    } else if (dotCount == 1) {
      // Pisahkan bagian integer dan desimal
      final List<String> parts = text.split('.');
      integerPart = parts[0];
      decimalPart = parts.length > 1 ? parts[1] : null;
      
      // Jika decimal part ada dan lebih dari 3 digit, kemungkinan ribuan separator
      if (decimalPart != null && decimalPart.length > 3) {
        // Kemungkinan ribuan separator, gabungkan kembali
        integerPart = integerPart + decimalPart;
        decimalPart = null;
      }
    } else {
      integerPart = text;
      decimalPart = null;
    }

    // Hapus semua karakter non-angka dari bagian integer
    integerPart = integerPart.replaceAll(RegExp(r'[^0-9]'), '');

    if (integerPart.isEmpty) {
      return newValue;
    }

    // Format bagian integer dengan titik pemisah ribuan
    final String formattedInteger = _formatWithDots(integerPart);

    // Gabungkan kembali dengan bagian desimal jika ada
    String finalText = formattedInteger;
    if (decimalPart != null && decimalPart.isNotEmpty) {
      finalText += '.' + decimalPart;
    }

    return TextEditingValue(
      text: finalText,
      selection: TextSelection.collapsed(offset: finalText.length),
    );
  }
}

class TransactionFormScreen extends StatefulWidget {
  final models.Transaction? transaction;
  final VoidCallback onSave;

  const TransactionFormScreen({
    super.key,
    this.transaction,
    required this.onSave,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late String _selectedType;
  late String _selectedCategory;

  final Map<String, List<String>> _categories = {
    'income': ['Gaji', 'Bonus', 'Investasi', 'Lainnya'],
    'expense': ['Makanan', 'Transportasi', 'Hiburan', 'Belanja', 'Tagihan', 'Lainnya'],
  };

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.transaction?.description ?? '',
    );
    _amountController = TextEditingController(
      text: widget.transaction != null ? _formatAmountForEditing(widget.transaction!.amount) : '',
    );
    _selectedDate = widget.transaction?.date ?? DateTime.now();
    _selectedType = widget.transaction?.type ?? 'expense';
    _selectedCategory = widget.transaction?.category ?? (_selectedType == 'expense' ? 'Lainnya' : 'Gaji');
  }

  // Helper untuk format amount saat editing
  String _formatAmountForEditing(double amount) {
    final int amountInt = amount.toInt();
    return _formatWithDots(amountInt.toString());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            datePickerTheme: const DatePickerThemeData(
              headerBackgroundColor: Color(0xFF1565C0),
              headerForegroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_descriptionController.text.isEmpty || _amountController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Semua field harus diisi'),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    try {
      // Hapus titik pemisah ribuan sebelum parsing
      final String cleanAmount = _amountController.text.replaceAll('.', '');
      final amount = double.parse(cleanAmount);
      
      final transaction = models.Transaction(
        id: widget.transaction?.id,
        description: _descriptionController.text,
        amount: amount,
        category: _selectedCategory,
        type: _selectedType,
        date: _selectedDate,
      );

      if (widget.transaction == null) {
        await _dbHelper.insertTransaction(transaction);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Transaksi berhasil ditambahkan'),
              backgroundColor: AppColors.income,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        await _dbHelper.updateTransaction(transaction);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Transaksi berhasil diperbarui'),
              backgroundColor: AppColors.income,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }

      if (mounted) {
        widget.onSave();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.transaction == null ? 'Tambah Transaksi' : 'Edit Transaksi',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Type selector (modern toggle with gradient)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = 'income';
                          _selectedCategory = _categories['income']![0];
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _selectedType == 'income' ? AppColors.income : null,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              color: _selectedType == 'income' ? Colors.white : AppColors.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pemasukan',
                              style: TextStyle(
                                color: _selectedType == 'income' ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = 'expense';
                          _selectedCategory = _categories['expense']![0];
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _selectedType == 'expense' ? AppColors.expense : null,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              color: _selectedType == 'expense' ? Colors.white : AppColors.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pengeluaran',
                              style: TextStyle(
                                color: _selectedType == 'expense' ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Description field
                  TextField(
                    controller: _descriptionController,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Deskripsi',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount field
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      _ThousandsSeparatorFormatter(),
                    ],
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Jumlah',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixText: 'Rp ',
                      prefixStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: _categories[_selectedType]!.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(
                          category,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                    dropdownColor: AppColors.surface,
                  ),
                  const SizedBox(height: 16),

                  // Date picker
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            'Ubah',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Save button with purple-pink gradient
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  widget.transaction == null ? 'Simpan' : 'Perbarui',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
