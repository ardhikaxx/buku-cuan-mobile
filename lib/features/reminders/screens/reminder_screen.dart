import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final ReminderService _reminderService = ReminderService();
  List<ReminderModel> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  void _loadReminders() {
    final provider = context.read<AppProvider>();
    if (provider.workspaceId == null) return;

    _reminderService.getReminders(provider.workspaceId!).listen((reminders) {
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeReminders = _reminders.where((r) => !r.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Reminder')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : activeReminders.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) => RefreshIndicator(
                    onRefresh: () async => _loadReminders(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: const Center(
                          child: EmptyState(
                            icon: Icons.notifications_none,
                            title: 'Tidak ada reminder',
                            subtitle: 'Reminder akan muncul saat Anda membuat hutang atau piutang.',
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadReminders(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...activeReminders.map((reminder) => _ReminderTile(
                            reminder: reminder,
                            onComplete: () => _markCompleted(reminder),
                            onDelete: () => _deleteReminder(reminder),
                          )),
                    ],
                  ),
                ),
    );
  }

  Future<void> _markCompleted(ReminderModel reminder) async {
    await _reminderService.markCompleted(reminder.id);
  }

  Future<void> _deleteReminder(ReminderModel reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Reminder'),
        content: const Text('Apakah Anda yakin ingin menghapus reminder ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _reminderService.deleteReminder(reminder.id);
    }
  }
}

class _ReminderTile extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _ReminderTile({
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
              reminder.isDebt ? Icons.money_off : Icons.request_page,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
            icon: const Icon(Icons.check_circle_outline, size: 22),
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}
