import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/receivable_model.dart';
import '../services/receivable_service.dart';
import 'add_receivable_screen.dart';

class ReceivableListScreen extends StatefulWidget {
  const ReceivableListScreen({super.key});

  @override
  State<ReceivableListScreen> createState() => _ReceivableListScreenState();
}

class _ReceivableListScreenState extends State<ReceivableListScreen> {
  final ReceivableService _receivableService = ReceivableService();
  List<ReceivableModel> _receivables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceivables();
  }

  void _loadReceivables() {
    final provider = context.read<AppProvider>();
    if (provider.workspaceId == null) return;

    _receivableService.getReceivables(provider.workspaceId!).listen((receivables) {
      setState(() {
        _receivables = receivables;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeReceivables = _receivables.where((r) => r.status != ReceivableStatus.paid).toList();
    final totalRemaining = activeReceivables.fold<double>(0, (sum, r) => sum + r.remainingAmount);

    return Scaffold(
      appBar: AppBar(title: const Text('Piutang')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _receivables.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) => RefreshIndicator(
                    onRefresh: () async => _loadReceivables(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: EmptyState(
                            icon: Iconsax.card_receive,
                            title: 'Belum ada piutang',
                            subtitle: 'Catat piutang dari pelanggan Anda.',
                            actionLabel: 'Tambah Piutang',
                            onAction: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddReceivableScreen()),
                              );
                              _loadReceivables();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadReceivables(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (activeReceivables.isNotEmpty) ...[
                        Container(
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
                                  const Text('Total Piutang Belum Dibayar',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  Text(
                                    CurrencyFormatter.formatRupiah(totalRemaining),
                                    style: const TextStyle(
                                        fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.receivable),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ...(_receivables.map((r) => _ReceivableTile(
                            receivable: r,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AddReceivableScreen(existingReceivable: r)),
                              );
                            },
                          ))),
                    ],
                  ),
                ),
    );
  }
}

class _ReceivableTile extends StatelessWidget {
  final ReceivableModel receivable;
  final VoidCallback onTap;

  const _ReceivableTile({required this.receivable, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = receivable.status == ReceivableStatus.paid
        ? AppColors.success
        : receivable.status == ReceivableStatus.partial
            ? AppColors.warning
            : AppColors.receivable;

    final statusText = receivable.status == ReceivableStatus.paid
        ? 'Lunas'
        : receivable.status == ReceivableStatus.partial
            ? 'Sebagian'
            : 'Belum Dibayar';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.receivable.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.user, color: AppColors.receivable, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(receivable.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Jatuh tempo: ${DateFormatter.formatDate(receivable.dueDate)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(CurrencyFormatter.formatRupiah(receivable.remainingAmount),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(statusText,
                      style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
