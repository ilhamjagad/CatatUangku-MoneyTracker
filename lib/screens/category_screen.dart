import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart' as models;

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  DateTime _selectedMonth = DateTime.now();
  List<models.Transaction> _transactions = [];
  bool _isLoading = false;

  final Map<String, List<String>> _allCategories = {
    'income': ['Gaji', 'Bonus', 'Investasi', 'Lainnya'],
    'expense': ['Makanan', 'Transportasi', 'Hiburan', 'Belanja', 'Tagihan', 'Lainnya'],
  };

  @override
  void initState() {
    super.initState();
    // Initial load is handled by didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data setiap kali screen menjadi aktif
    if (ModalRoute.of(context)?.isCurrent == true) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    developer.log('CategoryScreen: Loading transactions for ${_selectedMonth.month}/${_selectedMonth.year}', name: 'Performance');
    
    // Use optimized query that filters at SQL level
    final transactions = await _dbHelper.getTransactionsByMonth(_selectedMonth.month, _selectedMonth.year);
    developer.log('CategoryScreen: Found ${transactions.length} transactions', name: 'Performance');
    
    setState(() {
      _transactions = transactions;
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
        1,
      );
      _loadData();
    });
  }

  Map<String, double> _getCategoryTotals() {
    final totals = <String, double>{};
    for (var t in _transactions) {
      final key = '${t.category.trim()}_${t.type}';
      totals[key] = (totals[key] ?? 0) + t.amount;
    }
    
    // Add all predefined categories with 0 if not exists
    for (var type in ['income', 'expense']) {
      for (var cat in _allCategories[type]!) {
        final key = '${cat}_$type';
        if (!totals.containsKey(key)) {
          totals[key] = 0;
        }
      }
    }
    
    return totals;
  }

  Map<String, List<models.Transaction>> _getTransactionsByCategory() {
    final grouped = <String, List<models.Transaction>>{};
    for (var t in _transactions) {
      final key = '${t.category.trim()}_${t.type}';
      grouped.putIfAbsent(key, () => []).add(t);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat.yMMMM('id_ID').format(_selectedMonth);
    final categoryTotals = _getCategoryTotals();
    final transactionsByCategory = _getTransactionsByCategory();
    final totalAmount = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final categoriesWithTransactions = categoryTotals.entries.where((e) => e.value > 0).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: const Text(
            'Kategori',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildMonthSelector(monthLabel),
          const SizedBox(height: 16),
          _buildTotalCard(totalAmount, categoriesWithTransactions),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: Colors.purple,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : categoriesWithTransactions == 0
                      ? _buildEmptyState()
                      : _buildCategoryList(transactionsByCategory, categoryTotals),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(String monthLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
            color: Colors.purple,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              monthLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(double total, int categoryCount) {
    final formatted = NumberFormat('#,##0', 'id_ID').format(total);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple.shade400, Colors.purple.shade700],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category, color: Colors.white.withOpacity(0.8), size: 20),
              const SizedBox(width: 8),
              Text(
                '$categoryCount Kategori',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rp$formatted',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total Transaksi',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada transaksi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transaksi pada bulan ini akan\nmuncul di sini',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(
    Map<String, List<models.Transaction>> transactionsByCategory,
    Map<String, double> totals,
  ) {
    final sortedCategories = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final entry = sortedCategories[index];
        final key = entry.key;
        final category = key.split('_')[0];
        final type = key.split('_')[1];
        final isIncome = type == 'income';
        final total = entry.value;
        final transactions = transactionsByCategory[key] ?? [];
        final color = isIncome ? Colors.green.shade400 : Colors.red.shade400;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 20,
              ),
            ),
            title: Text(
              category,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              total > 0 ? '${transactions.length} transaksi' : 'Belum ada transaksi',
              style: TextStyle(
                fontSize: 13,
                color: total > 0 ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  total > 0 
                      ? 'Rp${NumberFormat('#,##0', 'id_ID').format(total)}'
                      : 'Rp0',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: total > 0 ? color : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  total > 0 ? Icons.expand_more : null,
                  color: total > 0 ? Colors.grey.shade400 : Colors.transparent,
                ),
              ],
            ),
            children: total > 0
                ? transactions.map((t) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        leading: Text(
                          DateFormat('dd', 'id_ID').format(t.date),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        title: Text(
                          t.description,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Text(
                          '${t.type == 'income' ? '+' : '-'} Rp${NumberFormat('#,##0', 'id_ID').format(t.amount)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: t.type == 'income' ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    );
                  }).toList()
                : [],
          ),
        );
      },
    );
  }
}
