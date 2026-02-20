import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryChart extends StatelessWidget {
  final double income;
  final double expense;

  const SummaryChart({super.key, required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final total = (income + expense) == 0 ? 1.0 : (income + expense);
    final incomePct = (income / total) * 100;
    final expensePct = (expense / total) * 100;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 28,
                sections: [
                  PieChartSectionData(
                    value: income,
                    color: Colors.green,
                    radius: 46,
                    title: '${incomePct.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: expense,
                    color: Colors.red,
                    radius: 46,
                    title: '${expensePct.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendItem(color: Colors.green, label: 'Pemasukan', value: income),
                  const SizedBox(height: 12),
                  _LegendItem(color: Colors.red, label: 'Pengeluaran', value: expense),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double value;

  const _LegendItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15), // ✅ lebih aman
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Rp${NumberFormat('#,##0', 'id_ID').format(value)}',
            style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 12),
          ),
        ),
      ],
    );
  }
}