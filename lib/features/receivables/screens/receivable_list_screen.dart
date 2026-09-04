import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/receivable_model.dart';
import '../services/receivable_service.dart';
import '../widgets/receivable_list_tile.dart';
import '../widgets/receivable_summary_card.dart';
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
                        ReceivableSummaryCard(totalRemaining: totalRemaining),
                        const SizedBox(height: 16),
                      ],
                      ...(_receivables.map((r) => ReceivableListTile(
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
