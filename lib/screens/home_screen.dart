import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart' as models;
import 'transaction_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late Future<List<models.Transaction>> _transactionsFuture;

  double _totalIncome = 0;
  double _totalExpense = 0;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'CatatUangku!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      icon: Icons.arrow_downward,
                      label: 'Pemasukan',
                      value: _formatCurrency(_totalIncome),
                      color: Colors.green[300]!,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white24,
                    ),
                    _buildSummaryItem(
                      icon: Icons.arrow_upward,
                      label: 'Pengeluaran',
                      value: _formatCurrency(_totalExpense),
                      color: Colors.red[300]!,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Month Navigation
          Padding(
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
                        color: Colors.grey.withOpacity(0.1),
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
          ),

          const SizedBox(height: 8),

          // Transaction List
          Expanded(
            child: FutureBuilder<List<models.Transaction>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.purple));
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
                  color: Colors.purple,
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
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const TextSpan(text: ' '),
                                      TextSpan(
                                        text: dateKey,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '+${_formatCurrency(list.where((t) => t.type == 'income').fold(0, (sum, t) => sum + t.amount))}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '-${_formatCurrency(list.where((t) => t.type == 'expense').fold(0, (sum, t) => sum + t.amount))}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
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
                                    color: Colors.grey.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  t.category,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      (isIncome ? '+' : '-') + formattedAmount,
                                      style: TextStyle(
                                        color: isIncome ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: Colors.grey[400],
                                        size: 20,
                                      ),
                                      onSelected: (value) async {
                                        if (value == 'edit') {
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
                                        } else if (value == 'delete') {
                                          await _dbHelper.deleteTransaction(t.id!);
                                          _refreshData();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Transaksi "${t.description}" dihapus'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 18, color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, size: 18, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Hapus'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
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
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
}
