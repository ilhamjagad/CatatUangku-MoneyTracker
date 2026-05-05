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
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

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
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
    
    if (!mounted) return;
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

  Map<String, Map<String, double>> _getCategoryGroupedTotals() {
    final grouped = <String, Map<String, double>>{};
    for (var t in _transactions) {
      final category = t.category.trim();
      final type = t.type;
      
      grouped.putIfAbsent(category, () => {'income': 0, 'expense': 0});
      grouped[category]![type] = (grouped[category]![type] ?? 0) + t.amount;
    }
    
    return grouped;
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
    final categoryGrouped = _getCategoryGroupedTotals();
    final totalAmount = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final categoriesWithTransactions = categoryGrouped.entries.where((e) {
      final income = e.value['income'] ?? 0;
      final expense = e.value['expense'] ?? 0;
      return (income + expense) > 0;
    }).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
            ),
          ),
        ),
        title: _isSearching
            ? TextField(
                focusNode: _searchFocusNode,
                controller: _searchController,
                style: const TextStyle(color: Colors.black, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Cari kategori...',
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.7)),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.black.withOpacity(0.8)),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : const Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
        titleSpacing: 16,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                } else {
                  _isSearching = true;
                }
              });
              // Request focus after setState to ensure the TextField is rendered
              if (_isSearching) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  FocusScope.of(context).requestFocus(_searchFocusNode);
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildTotalCard(totalAmount, categoriesWithTransactions),
          const SizedBox(height: 20),
          _buildMonthSelector(monthLabel),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: Color(0xFF0D47A1),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : categoriesWithTransactions == 0
                      ? _buildEmptyState()
                      : _buildInteractiveCategoryList(categoryGrouped),
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
            color: Color(0xFF0D47A1),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              monthLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
            color: Color(0xFF0D47A1),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(double total, int categoryCount) {
    final formatted = NumberFormat('#,##0', 'id_ID').format(total);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF0D47A1).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle in top right
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Transaksi',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rp$formatted',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: Colors.white.withOpacity(0.9),
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.category,
                      color: Colors.white.withOpacity(0.9),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$categoryCount Kategori',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            'Transaksi pada bulan ini akan muncul di sini',
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

  Widget _buildInteractiveCategoryList(
    Map<String, Map<String, double>> categoryGrouped,
  ) {
    // Get transactions by category to find the latest date
    final transactionsByCategory = _getTransactionsByCategory();
    
    // Sort categories by most recent transaction date
    final sortedCategories = categoryGrouped.entries.toList()
      ..sort((a, b) {
        final catA = a.key;
        final catB = b.key;
        
        // Get latest transaction date for category A
        final transA = transactionsByCategory['${catA}_income'] ?? [];
        final transA2 = transactionsByCategory['${catA}_expense'] ?? [];
        final allTransA = [...transA, ...transA2];
        DateTime? latestDateA;
        if (allTransA.isNotEmpty) {
          latestDateA = allTransA.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b);
        }
        
        // Get latest transaction date for category B
        final transB = transactionsByCategory['${catB}_income'] ?? [];
        final transB2 = transactionsByCategory['${catB}_expense'] ?? [];
        final allTransB = [...transB, ...transB2];
        DateTime? latestDateB;
        if (allTransB.isNotEmpty) {
          latestDateB = allTransB.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b);
        }
        
        // Sort by most recent date (newest first)
        if (latestDateA == null && latestDateB == null) return 0;
        if (latestDateA == null) return 1;
        if (latestDateB == null) return -1;
        return latestDateB.compareTo(latestDateA);
      });

    // Filter categories based on search query
    final filteredCategories = _searchQuery.isEmpty
        ? sortedCategories
        : sortedCategories
            .where((entry) =>
                entry.key.toLowerCase().contains(_searchQuery))
            .toList();

    if (filteredCategories.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Kategori tidak ditemukan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba cari dengan nama kategori lain',
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

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filteredCategories.length,
      itemBuilder: (context, index) {
        final entry = filteredCategories[index];
        final category = entry.key;
        final income = entry.value['income'] ?? 0;
        final expense = entry.value['expense'] ?? 0;
        
        if ((income + expense) == 0) {
          return const SizedBox.shrink();
        }

        // Get transactions for both income and expense of this category
        final incomeTransactions = transactionsByCategory['${category}_income'] ?? [];
        final expenseTransactions = transactionsByCategory['${category}_expense'] ?? [];
        final categoryTransactions = [...incomeTransactions, ...expenseTransactions];
        
        return _buildInteractiveCategoryCard(
          category,
          income,
          expense,
          categoryTransactions,
        );
      },
    );
  }

  Widget _buildInteractiveCategoryCard(String category, double income, double expense, List<models.Transaction> transactions) {
    final total = income + expense;
    
    final categoryIcons = {
      'Gaji': Icons.business_center,
      'Bonus': Icons.card_giftcard,
      'Investasi': Icons.trending_up,
      'Freelance': Icons.laptop,
      'Makanan': Icons.restaurant,
      'Transportasi': Icons.directions_car,
      'Hiburan': Icons.movie,
      'Belanja': Icons.shopping_bag,
      'Tagihan': Icons.receipt_long,
      'Kesehatan': Icons.local_hospital,
      'Lainnya': Icons.category,
    };
    
    final icon = categoryIcons[category] ?? categoryIcons['Lainnya']!;
    final formattedTotal = NumberFormat('#,##0', 'id_ID').format(total);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showCategoryDetail(category, income, expense, transactions);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.shade100,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.blue.shade600,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                category,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                'Rp$formattedTotal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${transactions.length} transaksi',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showCategoryDetail(String category, double income, double expense, List<models.Transaction> transactions) {
    final formattedIncome = NumberFormat('#,##0', 'id_ID').format(income);
    final formattedExpense = NumberFormat('#,##0', 'id_ID').format(expense);
    final total = income + expense;
    
    // Sort transactions by date descending
    final sortedTransactions = [...transactions]..sort((a, b) => b.date.compareTo(a.date));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return AnimatedPadding(
          padding: MediaQuery.of(context).viewInsets,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (income > 0 || expense > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (income > 0)
                              Column(
                                children: [
                                  Text(
                                    'Pemasukan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Rp$formattedIncome',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            if (expense > 0)
                              Column(
                                children: [
                                  Text(
                                    'Pengeluaran',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Rp$formattedExpense',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Detail Transaksi (${sortedTransactions.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: sortedTransactions.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada transaksi',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: sortedTransactions.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Colors.grey.shade200,
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final transaction = sortedTransactions[index];
                            final isIncome = transaction.type == 'income';
                            final color = isIncome ? Colors.green : Colors.red;
                            final sign = isIncome ? '+' : '-';
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                      size: 16,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          transaction.description,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('dd MMM yyyy', 'id_ID').format(transaction.date),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '$sign Rp${NumberFormat('#,##0', 'id_ID').format(transaction.amount)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
