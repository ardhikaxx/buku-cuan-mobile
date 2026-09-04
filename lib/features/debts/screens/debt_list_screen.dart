import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/debt_model.dart';
import '../services/debt_service.dart';
import 'add_debt_screen.dart';
import 'debt_detail_screen.dart';

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> {
  final DebtService _debtService = DebtService();
  List<DebtModel> _debts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  void _loadDebts() {
    final provider = context.read<AppProvider>();
    if (provider.workspaceId == null) return;

    _debtService.getDebts(provider.workspaceId!).listen((debts) {
      setState(() {
        _debts = debts;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeDebts = _debts.where((d) => d.status != DebtStatus.paid).toList();
    final totalRemaining = activeDebts.fold<double>(0, (sum, d) => sum + d.remainingAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hutang'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _debts.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) => RefreshIndicator(
                    onRefresh: () async => _loadDebts(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: EmptyState(
                            icon: Icons.money_off,
                            title: 'Belum ada hutang',
                            subtitle: 'Catat hutang yang belum Anda bayar.',
                            actionLabel: 'Tambah Hutang',
                            onAction: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddDebtScreen()),
                              );
                              _loadDebts();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadDebts(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (activeDebts.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.debt.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.debt.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.money_off, color: AppColors.debt, size: 32),
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
                        ),
                        const SizedBox(height: 16),
                      ],
                      ...(_debts.map((debt) => _DebtTile(
                        debt: debt,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DebtDetailScreen(debt: debt),
                          ),
                        ),
                      ))),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDebtScreen()),
          );
        },
        backgroundColor: AppColors.debt,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _DebtTile extends StatelessWidget {
  final DebtModel debt;
  final VoidCallback onTap;

  const _DebtTile({required this.debt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = debt.status == DebtStatus.paid
        ? AppColors.success
        : debt.status == DebtStatus.partial
            ? AppColors.warning
            : AppColors.danger;

    final statusText = debt.status == DebtStatus.paid
        ? 'Lunas'
        : debt.status == DebtStatus.partial
            ? 'Sebagian'
            : 'Belum Lunas';

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
                color: AppColors.debt.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person, color: AppColors.debt, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Jatuh tempo: ${DateFormatter.formatDate(debt.dueDate)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatRupiah(debt.remainingAmount),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
