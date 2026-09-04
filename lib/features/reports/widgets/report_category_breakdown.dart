import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class ReportCategoryBreakdown extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color headerColor;
  final List<Map<String, dynamic>> items;
  final List<Color> palette;

  const ReportCategoryBreakdown({
    super.key,
    required this.title,
    required this.icon,
    required this.headerColor,
    required this.items,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(
        0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: headerColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (total > 0) ...[
            SizedBox(
              height: 170,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: items.asMap().entries.map((entry) {
                    final amount =
                        (entry.value['amount'] as num?)?.toDouble() ?? 0.0;
                    final percentage =
                        total > 0 ? (amount / total * 100) : 0.0;
                    final color = palette[entry.key % palette.length];
                    return PieChartSectionData(
                      value: amount,
                      title: percentage >= 5
                          ? '${percentage.toStringAsFixed(0)}%'
                          : '',
                      color: color,
                      radius: 46,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          ...items.asMap().entries.map((entry) {
            final color = palette[entry.key % palette.length];
            final amount =
                (entry.value['amount'] as num?)?.toDouble() ?? 0.0;
            final category = entry.value['category'] as String? ?? 'Lainnya';
            final percentage = total > 0 ? (amount / total * 100) : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.formatRupiah(amount),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
