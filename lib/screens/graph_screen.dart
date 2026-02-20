import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
    
    developer.log('GraphScreen: Loaded ${list.length} transactions', name: 'Performance');
    
    setState(() {
      _categoryIncome = income;
      _categoryExpense = expense;
      _income = totals['income']!;
      _expense = totals['expense']!;
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
    DateFormat.yMMMM('id_ID').format(_selectedMonth);
    final total = _income + _expense;
    final double incomePercent = total == 0 ? 0 : (_income / total) * 100;
    final double expensePercent = total == 0 ? 0 : (_expense / total) * 100;

    final allCategories = {
      ..._categoryIncome,
      ..._categoryExpense,
    }.keys.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'Statistik',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildMonthSelector(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Pemasukan',
                        _income,
                        Colors.green.shade400,
                        Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Pengeluaran',
                        _expense,
                        Colors.red.shade400,
                        Icons.arrow_upward,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildPieChartSection(incomePercent, expensePercent),
              const SizedBox(height: 24),
              _buildBarChartSection(allCategories),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    final selectedMonth = DateFormat.MMMM('id_ID').format(_selectedMonth);
    final selectedYear = _selectedMonth.year.toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedMonth,
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
                _selectedMonth = DateTime(picked.year, picked.month, 1);
                _loadData();
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.calendar_month, color: Colors.purple[600]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Periode',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$selectedMonth $selectedYear',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.chevron_left, size: 20, color: Colors.purple[600]),
                      ),
                      onPressed: () => _changeMonth(-1),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.chevron_right, size: 20, color: Colors.purple[600]),
                      ),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    final formattedAmount = NumberFormat('#,##0', 'id_ID').format(amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rp$formattedAmount',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection(double incomePercent, double expensePercent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Ringkasan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 160,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 45,
                    sections: [
                      PieChartSectionData(
                        value: _income,
                        color: Colors.green.shade400,
                        title: '${incomePercent.toStringAsFixed(0)}%',
                        radius: 25,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: _expense,
                        color: Colors.red.shade400,
                        title: '${expensePercent.toStringAsFixed(0)}%',
                        radius: 25,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(
                      'Pemasukan',
                      Colors.green.shade400,
                      Icons.arrow_downward,
                      _income,
                    ),
                    const SizedBox(height: 10),
                    _buildLegendItem(
                      'Pengeluaran',
                      Colors.red.shade400,
                      Icons.arrow_upward,
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

  Widget _buildLegendItem(
    String label,
    Color color,
    IconData icon,
    double amount,
  ) {
    final formattedAmount = NumberFormat('#,##0', 'id_ID').format(amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 22),
          child: Text(
            'Rp$formattedAmount',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChartSection(List<String> allCategories) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      height: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: allCategories.isEmpty
                ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada data',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
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
                              width: 12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            BarChartRodData(
                              toY: expense,
                              color: Colors.red.shade400,
                              width: 12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                NumberFormat.compactSimpleCurrency(
                                  locale: 'id_ID',
                                ).format(value),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 &&
                                  index < allCategories.length) {
                                return Transform.rotate(
                                  angle: -0.5,
                                  child: Text(
                                    allCategories[index],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
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
