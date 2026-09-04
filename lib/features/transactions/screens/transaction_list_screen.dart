import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../widgets/transaction_list_tile.dart';
import 'add_transaction_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TransactionService _transactionService = TransactionService();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    final provider = context.read<AppProvider>();
    if (provider.workspaceId == null) return;

    _transactionService.getTransactions(provider.workspaceId!).listen((transactions) {
      setState(() {
        _transactions = _filterTransactions(transactions);
        _isLoading = false;
      });
    });
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> all) {
    if (_filterType == 'all') return all;
    return all.where((t) => t.type == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterType = value;
                _isLoading = true;
              });
              _loadTransactions();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Semua')),
              const PopupMenuItem(value: 'income', child: Text('Pemasukan')),
              const PopupMenuItem(value: 'expense', child: Text('Pengeluaran')),
            ],
            icon: const Icon(Iconsax.filter),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) => RefreshIndicator(
                    onRefresh: () async => _loadTransactions(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: EmptyState(
                            icon: Iconsax.receipt_text,
                            title: 'Belum ada transaksi',
                            subtitle: 'Mulai catat pemasukan atau pengeluaran usaha Anda.',
                            actionLabel: 'Tambah Transaksi',
                            onAction: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                              );
                              _loadTransactions();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadTransactions(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      return TransactionListTile(
                        transaction: _transactions[index],
                        onDelete: () => _deleteTransaction(_transactions[index]),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  void _deleteTransaction(TransactionModel transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _transactionService.deleteTransaction(transaction.id);
    }
  }
}
