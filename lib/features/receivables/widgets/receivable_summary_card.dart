import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class ReceivableSummaryCard extends StatelessWidget {
  final double totalRemaining;

  const ReceivableSummaryCard({
    super.key,
    required this.totalRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.receivable.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.receivable.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.card_receive, color: AppColors.receivable, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Piutang Belum Dibayar',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                CurrencyFormatter.formatRupiah(totalRemaining),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.receivable,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
