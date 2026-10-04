import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ModernBarChart extends StatelessWidget {
  final Map<String, double> data;

  const ModernBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Ambil data real berdasarkan urutan periode
    final List<MapEntry<String, double>> entries = [];
    final periods = ['Periode 1', 'Periode 2', 'Periode 3', 'Periode 4', 'Mykost'];
    
    for (var p in periods) {
      double value = 0.0;
      final matchingKey = data.keys.firstWhere(
        (k) => k.toLowerCase().contains(p.toLowerCase()), 
        orElse: () => '',
      );
      
      if (matchingKey.isNotEmpty) {
        value = data[matchingKey]!;
      }
      entries.add(MapEntry(p, value));
    }

    debugPrint('Chart: Menampilkan data REAL dari database.');

    final maxVal = entries.isNotEmpty 
        ? entries.map((e) => e.value).reduce((a, b) => a > b ? a : b)
        : 100.0;
    final topLimit = (maxVal * 1.3);

    final isMobile = MediaQuery.of(context).size.width < 850;
    final barWidth = isMobile ? 28.0 : 44.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: topLimit,
        barTouchData: BarTouchData(
          enabled: false,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                formatLabel(rod.toY),
                TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 11 : 14,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < 0 || value.toInt() >= entries.length) {
                  return const SizedBox();
                }
                String label = entries[value.toInt()].key;
                if (label.contains('Periode 1')) {
                  label = 'P1';
                } else if (label.contains('Periode 2')) {
                  label = 'P2';
                } else if (label.contains('Periode 3')) {
                  label = 'P3';
                } else if (label.contains('Periode 4')) {
                  label = 'P4';
                }
                
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.black45, 
                      fontSize: isMobile ? 11 : 13, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(entries.length, (index) {
          final color = _getBarColor(entries[index].key); 
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entries[index].value,
                color: color,
                width: barWidth,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(show: false),
              ),
            ],
            showingTooltipIndicators: [0],
          );
        }),
      ),
    );
  }

  Color _getBarColor(String label) {
    if (label.contains('Periode 1')) return const Color(0xFF007AFF); // Blue
    if (label.contains('Periode 2')) return const Color(0xFF34C759); // Green
    if (label.contains('Periode 3')) return const Color(0xFF00BCD4); // Cyan/Light Blue
    if (label.contains('Periode 4')) return const Color(0xFF0056B3); // Navy/Dark Blue
    if (label.contains('Mykost')) return const Color(0xFFFF9F00); // Orange
    return const Color(0xFF8E8E93); // Gray fallback
  }

  String formatLabel(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1).replaceAll('.', ',')} M';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toInt()} juta';
    }
    return amount.toString();
  }
}
