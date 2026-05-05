import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../database/database_helper.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  DateTime _selectedMonth = DateTime.now();
  Map<String, double> _categoryIncome = {};
  Map<String, double> _categoryExpense = {};
  double _income = 0;
  double _expense = 0;
  double _prevIncome = 0;
  double _prevExpense = 0;

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
    developer.log('GraphScreen: Loading data for ${_selectedMonth.month}/${_selectedMonth.year}', name: 'Performance');
    
    // Load transactions filtered by month
    final list = await _dbHelper.getTransactionsByMonth(_selectedMonth.month, _selectedMonth.year);
    
    // Use optimized aggregation for totals
    final totals = await _dbHelper.getTotalByType(_selectedMonth.month, _selectedMonth.year);
    
    // Group by category
    final Map<String, double> income = {};
    final Map<String, double> expense = {};
    
    for (var t in list) {
      if (t.type == 'income') {
        income[t.category] = (income[t.category] ?? 0) + t.amount;
      } else {
        expense[t.category] = (expense[t.category] ?? 0) + t.amount;
      }
    }
    
    // Load previous month data
    final previousMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    final prevTotals = await _dbHelper.getTotalByType(previousMonth.month, previousMonth.year);
    
    developer.log('GraphScreen: Loaded ${list.length} transactions', name: 'Performance');
    
    if (!mounted) return;
    
    setState(() {
      _categoryIncome = income;
      _categoryExpense = expense;
      _income = totals['income']!;
      _expense = totals['expense']!;
      _prevIncome = prevTotals['income']!;
      _prevExpense = prevTotals['expense']!;
    });
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

  @override
  Widget build(BuildContext context) {
    final total = _income + _expense;
    final double incomePercent = total == 0 ? 0 : (_income / total) * 100;
    final double expensePercent = total == 0 ? 0 : (_expense / total) * 100;

    final allCategories = {
      ..._categoryIncome,
      ..._categoryExpense,
    }.keys.toList();

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: const Text(
            'Statistik',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
              children: [
                const SizedBox(height: 20),
                _buildMonthSelector(),
                const SizedBox(height: 24),
                _buildComparisonInsight(),
                const SizedBox(height: 24),
                _buildPieChartSection(incomePercent, expensePercent),
                const SizedBox(height: 24),
                _buildBarChartSection(allCategories),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildComparisonInsight() {
    final incomeDiff = _income - _prevIncome;
    final expenseDiff = _expense - _prevExpense;
    
    final incomeChangePercent = _prevIncome == 0 ? 0.0 : (incomeDiff / _prevIncome) * 100;
    final expenseChangePercent = _prevExpense == 0 ? 0.0 : (expenseDiff / _prevExpense) * 100;

    final formattedIncome = NumberFormat('#,##0', 'id_ID').format(_income);
    final formattedPrevIncome = NumberFormat('#,##0', 'id_ID').format(_prevIncome);
    final formattedExpense = NumberFormat('#,##0', 'id_ID').format(_expense);
    final formattedPrevExpense = NumberFormat('#,##0', 'id_ID').format(_prevExpense);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insight Keuangan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedInsightCard(
                  'Pemasukan',
                  _income,
                  formattedPrevIncome,
                  incomeChangePercent,
                  Colors.green,
                  Icons.trending_up,
                  _prevIncome == 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedInsightCard(
                  'Pengeluaran',
                  _expense,
                  formattedPrevExpense,
                  expenseChangePercent,
                  Colors.red,
                  Icons.trending_down,
                  _prevExpense == 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInsightCard(
    String label,
    double currentAmount,
    String prevAmount,
    double changePercent,
    Color baseColor,
    IconData icon,
    bool isNoPrevData,
  ) {
    final isPositive = changePercent >= 0;
    final isIncome = label == 'Pemasukan';
    
    // Untuk expense: jika pengeluaran turun (negative) itu GOOD (hijau), naik itu BAD (orange)
    // Untuk income: jika income naik (positive) itu GOOD (hijau), turun itu BAD (orange)
    bool isGood;
    Color displayColor;
    
    if (isIncome) {
      isGood = isPositive;
      displayColor = baseColor; // Green untuk income
    } else {
      isGood = !isPositive; // Expense turun = baik
      // Jika expense turun (isGood = true), tampilkan hijau
      // Jika expense naik (isGood = false), tampilkan orange
      displayColor = isGood ? Colors.green : Colors.orange;
    }
    
    final statusColor = isGood ? displayColor : Colors.orange;
    
    final formattedCurrent = NumberFormat('#,##0', 'id_ID').format(currentAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: baseColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rp$formattedCurrent',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: baseColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: statusColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  isNoPrevData ? 'N/A' : '${changePercent.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isNoPrevData ? 'Bulan lalu: Rp$prevAmount' : 'Rp$prevAmount bln lalu',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final monthLabel = DateFormat.yMMMM('id_ID').format(_selectedMonth);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
            color: Color.fromARGB(255, 255, 255, 255),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
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
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection(double incomePercent, double expensePercent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Bulan Ini',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        value: _income,
                        color: Colors.green.shade400,
                        title: '${incomePercent.toStringAsFixed(0)}%',
                        radius: 24,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: _expense,
                        color: Colors.red.shade400,
                        title: '${expensePercent.toStringAsFixed(0)}%',
                        radius: 24,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEnhancedLegendItem(
                      'Pemasukan',
                      Colors.green.shade400,
                      Icons.trending_up,
                      _income,
                    ),
                    const SizedBox(height: 16),
                    _buildEnhancedLegendItem(
                      'Pengeluaran',
                      Colors.red.shade400,
                      Icons.trending_down,
                      _expense,
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

  Widget _buildEnhancedLegendItem(
    String label,
    Color color,
    IconData icon,
    double amount,
  ) {
    final formattedAmount = NumberFormat('#,##0', 'id_ID').format(amount);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 12, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Rp$formattedAmount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartSection(List<String> allCategories) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      height: 410,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analisis Kategori',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: allCategories.isEmpty
                ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.bar_chart,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada data',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                : BarChart(
                    BarChartData(
                      barGroups: allCategories.map((category) {
                        final income = _categoryIncome[category] ?? 0;
                        final expense = _categoryExpense[category] ?? 0;
                        return BarChartGroupData(
                          x: allCategories.indexOf(category),
                          barRods: [
                            BarChartRodData(
                              toY: income,
                              color: Colors.green.shade400,
                              width: 10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            BarChartRodData(
                              toY: expense,
                              color: Colors.red.shade400,
                              width: 10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                NumberFormat.compactSimpleCurrency(
                                  locale: 'id_ID',
                                ).format(value),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 &&
                                  index < allCategories.length) {
                                return Transform.rotate(
                                  angle: -0.5,
                                  child: Text(
                                    allCategories[index],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 1000000,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
