import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';

class LocationPieChart extends StatelessWidget {
  final Map<String, int> data;

  const LocationPieChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<int>(0, (a, b) => a + b);
    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân bố theo khu vực',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: sorted.asMap().entries.map((entry) {
                        final pct = entry.value.value / total * 100;
                        return PieChartSectionData(
                          value: entry.value.value.toDouble(),
                          color: AppColors.chartColors[entry.key % AppColors.chartColors.length],
                          radius: 30,
                          showTitle: pct > 10,
                          title: '${pct.toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: sorted.take(5).toList().asMap().entries.map((entry) {
                      final pct = (entry.value.value / total * 100).toStringAsFixed(0);
                      final color = AppColors.chartColors[entry.key % AppColors.chartColors.length];
                      final label = _shortenLocation(entry.value.key);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                label,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '$pct%',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortenLocation(String loc) {
    return loc
        .replaceAll('Thành phố ', 'TP. ')
        .replaceAll('Tỉnh ', '');
  }
}
