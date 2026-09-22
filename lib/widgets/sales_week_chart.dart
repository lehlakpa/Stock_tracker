import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/buyer_model.dart';
import '../utils/formatters.dart';

class SalesWeekChart extends StatelessWidget {
  const SalesWeekChart({super.key, required this.buyers});
  final List<BuyerModel> buyers;
  @override
  Widget build(BuildContext context) {
    final today = day(DateTime.now());
    final start = today.subtract(Duration(days: today.weekday - 1));
    final values = List.generate(
      7,
      (i) => buyers
          .where(
            (b) =>
                b.purchaseDate != null &&
                day(b.purchaseDate!) == start.add(Duration(days: i)),
          )
          .fold(0, (sum, b) => sum + b.quantity),
    );
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: (values.fold<int>(4, (a, b) => a > b ? a : b) + 2).toDouble(),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: colors.outlineVariant, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    ['M', 'T', 'W', 'T', 'F', 'S', 'S'][v.toInt().clamp(0, 6)],
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
          barGroups: List.generate(
            7,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  width: 20,
                  color: i == today.weekday - 1
                      ? colors.primary
                      : colors.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
