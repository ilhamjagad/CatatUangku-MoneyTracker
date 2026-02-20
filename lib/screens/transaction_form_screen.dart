import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart' as models;

// Modern purple-pink gradient color palette
class AppColors {
  static const Color primaryStart = Color(0xFF8B5CF6); // Purple
  static const Color primaryEnd = Color(0xFFEC4899); // Pink
  static const Color primary = Color(0xFF8B5CF6); // Purple as main primary
  static const Color income = Color(0xFF10B981); // Emerald green
  static const Color expense = Color(0xFFEF4444); // Modern red
  static const Color background = Color(0xFFFDF4FF); // Light pink
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFCE7F3); // Light pink
  static const Color textPrimary = Color(0xFF1F2937); // Dark grey
  static const Color textSecondary = Color(0xFF6B7280); // Medium grey
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFF8B5CF6); // Will be used with opacity in places
  static const Color shadow = Color(0xFF0F172A);

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
      text: widget.transaction?.amount.toString() ?? '',
    );
    _selectedDate = widget.transaction?.date ?? DateTime.now();
    _selectedType = widget.transaction?.type ?? 'expense';
    _selectedCategory = widget.transaction?.category ?? (_selectedType == 'expense' ? 'Lainnya' : 'Gaji');
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
            colorScheme: ColorScheme.light(
              primary: Color(0xFF8B5CF6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: Color(0xFF8B5CF6),
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
      final amount = double.parse(_amountController.text);
      
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
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.transaction == null ? 'Tambah Transaksi' : 'Edit Transaksi',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        shadowColor: AppColors.shadow.withOpacity(0.05),
      ),
      body: SingleChildScrollView(
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
                    initialValue: _selectedCategory,
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
    );
  }
}
