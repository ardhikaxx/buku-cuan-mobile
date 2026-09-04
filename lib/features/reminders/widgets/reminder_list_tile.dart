import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../models/reminder_model.dart';

class ReminderListTile extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const ReminderListTile({
    super.key,
    required this.reminder,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = reminder.daysUntilDue;
    final isOverdue = daysLeft < 0;
    final isUrgent = daysLeft <= 3 && daysLeft >= 0;

    final color = isOverdue
        ? AppColors.danger
        : isUrgent
            ? AppColors.warning
            : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              reminder.isDebt ? Iconsax.card_send : Iconsax.card_receive,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  isOverdue
                      ? 'Jatuh tempo ${-daysLeft} hari yang lalu'
                      : daysLeft == 0
                          ? 'Jatuh tempo hari ini'
                          : 'Jatuh tempo dalam $daysLeft hari',
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onComplete,
            icon: const Icon(Iconsax.tick_circle, size: 22),
            color: AppColors.success,
            tooltip: 'Tandai Selesai',
          ),
        ],
      ),
    );
  }
}
