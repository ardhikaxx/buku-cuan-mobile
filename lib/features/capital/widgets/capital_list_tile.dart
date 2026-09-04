import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../models/capital_model.dart';

class CapitalListTile extends StatelessWidget {
  final CapitalModel capital;

  const CapitalListTile({
    super.key,
    required this.capital,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (capital.isWithdrawal ? AppColors.danger : AppColors.success)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              capital.isWithdrawal ? Iconsax.money_send : Iconsax.money_recive,
              color: capital.isWithdrawal ? AppColors.danger : AppColors.success,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.capitalTypeLabels[capital.type] ?? capital.type,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormatter.formatDate(capital.date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${capital.isWithdrawal ? '-' : '+'}${CurrencyFormatter.formatRupiah(capital.amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: capital.isWithdrawal ? AppColors.danger : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
