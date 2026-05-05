import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart' as constants;
import '../database/database_helper.dart';
import '../models/transaction.dart' as models;
import '../services/auth_service.dart';
import 'transaction_form_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthService _authService = AuthService();
  late Future<List<models.Transaction>> _transactionsFuture;

  double _totalIncome = 0;
  double _totalExpense = 0;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh user data when returning from profile
    if (ModalRoute.of(context)?.isCurrent == true) {
      _loadUserName();
    }
  }

  String _userName = 'User';

  void _loadUserName() {
    final user = _authService.getCurrentUser();
    setState(() {
      _userName = user?.displayName ?? 'User';
    });
  }

  void _loadTransactions() {
    developer.log('HomeScreen: Loading transactions for ${_selectedMonth.month}/${_selectedMonth.year}', name: 'Performance');
    // Use optimized query that filters at SQL level
    _transactionsFuture = _dbHelper.getTransactionsByMonth(_selectedMonth.month, _selectedMonth.year)
      .catchError((error, stackTrace) {
        developer.log('HomeScreen: Error loading transactions: $error', name: 'Performance', error: error, stackTrace: stackTrace);
        return <models.Transaction>[]; // Return empty list on error
      });
    
    // Also load totals separately for efficiency
    _dbHelper.getTotalByType(_selectedMonth.month, _selectedMonth.year).then((totals) {
      developer.log('HomeScreen: Totals loaded - income: ${totals['income']}, expense: ${totals['expense']}', name: 'Performance');
      if (mounted) {
        setState(() {
          _totalIncome = totals['income'] ?? 0;
          _totalExpense = totals['expense'] ?? 0;
        });
      }
    }).catchError((error, stackTrace) {
      developer.log('HomeScreen: Error loading totals: $error', name: 'Performance', error: error, stackTrace: stackTrace);
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadTransactions();
    });
  }

  String _formatCurrency(double amount) {
    return 'Rp${NumberFormat('#,##0', 'id_ID').format(amount)}';
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1);
      _loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalBalance = _totalIncome - _totalExpense;
    final monthLabel = DateFormat.yMMMM('id_ID').format(_selectedMonth);

    return Scaffold(
      backgroundColor: constants.AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: constants.AppColors.primaryGradient,
          ),
        ),
        title: const Text(
          'CatatUangku!',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white, size: 24),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              _loadUserName();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Halo, $_userName!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: constants.AppColors.primary,
                ),
              ),
          ),
          // Balance Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Color(0xFF0D47A1).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(totalBalance),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 120,
                      child: _buildSummaryItem(
                        icon: Icons.arrow_downward,
                        label: 'Pemasukan',
                        value: _formatCurrency(_totalIncome),
                        color: Colors.green[300]!,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white24,
                    ),
                    SizedBox(
                      width: 110,
                      child: _buildSummaryItem(
                        icon: Icons.arrow_upward,
                        label: 'Pengeluaran',
                        value: _formatCurrency(_totalExpense),
                        color: Colors.red[300]!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Month Navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        // ignore: deprecated_member_use
                        color: Colors.black.withValues(alpha: 0.3),
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
          ),

          const SizedBox(height: 8),

          // Transaction List
          Expanded(
            child: FutureBuilder<List<models.Transaction>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1)));
                }
                if (snapshot.hasError) {
                  developer.log('HomeScreen: FutureBuilder error: ${snapshot.error}', name: 'Performance', error: snapshot.error);
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Terjadi kesalahan',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _refreshData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final transactions = snapshot.data ?? [];
                // No need to filter again since query is already filtered by month

                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada transaksi bulan ini',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                // Group by tanggal
                final Map<String, List<models.Transaction>> grouped = {};
                for (var t in transactions) {
                  final dateKey = DateFormat('dd MMM yyyy', 'id_ID').format(t.date);
                  grouped.putIfAbsent(dateKey, () => []).add(t);
                }

                final sortedKeys = grouped.keys.toList()
                  ..sort((a, b) {
                    final da = DateFormat('dd MMM yyyy', 'id_ID').parse(a);
                    final db = DateFormat('dd MMM yyyy', 'id_ID').parse(b);
                    return db.compareTo(da);
                  });

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  color: Color(0xFF0D47A1),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final dateKey = sortedKeys[index];
                      final list = grouped[dateKey]!;

                      return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Header with Summary
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: DateFormat('EEEE', 'id_ID').format(list.first.date),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: dateKey,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Optimize: Calculate totals once to avoid multiple fold operations
                          _buildDailySummary(list),
                        ],
                      ),
                    ),
                          // Transaction Cards
                          ...list.map((t) {
                            final isIncome = t.type == 'income';
                            final formattedAmount = _formatCurrency(t.amount);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: () => _showTransactionOptions(context, t),
                                borderRadius: BorderRadius.circular(12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      // ignore: deprecated_member_use
                                      color: (isIncome ? Colors.green : Colors.red).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: isIncome ? Colors.green : Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    t.description,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    t.category,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  trailing: Text(
                                    (isIncome ? '+' : '-') + formattedAmount,
                                    style: TextStyle(
                                      color: isIncome ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionFormScreen(onSave: _refreshData),
            ),
          );
          _refreshData();
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: constants.AppColors.primaryMid,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDailySummary(List<models.Transaction> list) {
    // Calculate totals once to avoid multiple fold operations
    double incomeTotal = 0;
    double expenseTotal = 0;
    for (var t in list) {
      if (t.type == 'income') {
        incomeTotal += t.amount;
      } else {
        expenseTotal += t.amount;
      }
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (incomeTotal > 0)
          Text(
            '+${_formatCurrency(incomeTotal)}',
            style: const TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (incomeTotal > 0 && expenseTotal > 0)
          const SizedBox(width: 8),
        if (expenseTotal > 0)
          Text(
            '-${_formatCurrency(expenseTotal)}',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showTransactionOptions(BuildContext context, models.Transaction t) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                t.description,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Transaksi'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TransactionFormScreen(
                        transaction: t,
                        onSave: _refreshData,
                      ),
                    ),
                  );
                  _refreshData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus Transaksi'),
                onTap: () async {
                  Navigator.pop(ctx);
                  // Show confirmation dialog
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Hapus Transaksi'),
                      content: Text('Apakah Anda yakin ingin menghapus transaksi "${t.description}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _dbHelper.deleteTransaction(t.id!);
                    _refreshData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Transaksi "${t.description}" dihapus'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
