import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/debt_model.dart';
import '../services/debt_service.dart';
import '../widgets/debt_list_tile.dart';
import '../widgets/debt_summary_card.dart';
import 'add_debt_screen.dart';
import 'debt_detail_screen.dart';

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> {
  final DebtService _debtService = DebtService();
  StreamSubscription<List<DebtModel>>? _subscription;
  List<DebtModel> _debts = [];
  bool _isLoading = true;
  String? _lastWorkspaceId;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<AppProvider>();
    final wid = provider.workspaceId;
    if (wid != null && wid.isNotEmpty && wid != _lastWorkspaceId) {
      _lastWorkspaceId = wid;
      _loadDebts();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _loadDebts() {
    final provider = context.read<AppProvider>();
    final wid = provider.workspaceId;
    if (wid == null || wid.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _subscription?.cancel();
    _subscription = _debtService.getDebts(wid).listen(
      (debts) {
        if (mounted) {
          setState(() {
            _debts = debts;
            _isLoading = false;
          });
        }
      },
      onError: (e) {
        debugPrint('Debt stream error: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
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
                            icon: Iconsax.card_send,
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
                        DebtSummaryCard(totalRemaining: totalRemaining),
                        const SizedBox(height: 16),
                      ],
                      ...(_debts.map((debt) => DebtListTile(
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
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }
}
