import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';
import '../widgets/reminder_list_tile.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final ReminderService _reminderService = ReminderService();
  StreamSubscription<List<ReminderModel>>? _subscription;
  List<ReminderModel> _reminders = [];
  bool _isLoading = true;
  String? _lastWorkspaceId;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<AppProvider>();
    final wid = provider.workspaceId;
    if (wid != null && wid.isNotEmpty && wid != _lastWorkspaceId) {
      _lastWorkspaceId = wid;
      _loadReminders();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _loadReminders() {
    final provider = context.read<AppProvider>();
    final wid = provider.workspaceId;
    if (wid == null || wid.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _subscription?.cancel();
    _subscription = _reminderService.getReminders(wid).listen(
      (reminders) {
        if (mounted) {
          setState(() {
            _reminders = reminders;
            _isLoading = false;
          });
        }
      },
      onError: (e) {
        debugPrint('Reminder stream error: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
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
                            icon: Iconsax.notification_bing,
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
                      ...activeReminders.map((reminder) => ReminderListTile(
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
