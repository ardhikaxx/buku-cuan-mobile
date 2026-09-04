import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class DebtSummaryCard extends StatelessWidget {
  final double totalRemaining;

  const DebtSummaryCard({
    super.key,
    required this.totalRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.debt.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.debt.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.card_send, color: AppColors.debt, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Hutang Belum Lunas',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                CurrencyFormatter.formatRupiah(totalRemaining),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.debt,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
