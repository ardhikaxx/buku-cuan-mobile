import 'dart:async';
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
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<List<TransactionModel>>? _subscription;
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _filterType = 'all';
  String _searchQuery = '';
  String? _lastWorkspaceId;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<AppProvider>();
    final wid = provider.workspaceId;
    if (wid != null && wid.isNotEmpty && wid != _lastWorkspaceId) {
      _lastWorkspaceId = wid;
      _loadTransactions();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadTransactions() {
    final provider = context.read<AppProvider>();
    final wid = provider.workspaceId;
    if (wid == null || wid.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _subscription?.cancel();
    _subscription = _transactionService.getTransactions(wid).listen(
      (transactions) {
        if (mounted) {
          setState(() {
            _allTransactions = transactions;
            _filteredTransactions = _applyFilterAndSearch(transactions);
            _isLoading = false;
          });
        }
      },
      onError: (e) {
        debugPrint('Transaction Stream Error: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  List<TransactionModel> _applyFilterAndSearch(List<TransactionModel> all) {
    return all.where((t) {
      final matchesFilter = _filterType == 'all' || t.type == _filterType;
      if (!matchesFilter) return false;

      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final matchDesc = t.description.toLowerCase().contains(q);
      final matchCat = t.categoryName.toLowerCase().contains(q);
      final matchNotes = t.notes?.toLowerCase().contains(q) ?? false;
      final matchAmount = t.amount.toString().contains(q);

      return matchDesc || matchCat || matchNotes || matchAmount;
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
      _filteredTransactions = _applyFilterAndSearch(_allTransactions);
    });
  }

  void _stopSearching() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
      _filteredTransactions = _applyFilterAndSearch(_allTransactions);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Iconsax.arrow_left),
                onPressed: _stopSearching,
              )
            : null,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Cari keterangan, kategori, nominal...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                ),
                onChanged: _onSearchChanged,
              )
            : const Text('Transaksi'),
        actions: [
          if (_isSearching) ...[
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Iconsax.close_circle, size: 20),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
          ] else ...[
            IconButton(
              icon: const Icon(Iconsax.search_normal),
              tooltip: 'Cari Transaksi',
              onPressed: () => setState(() => _isSearching = true),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  _filterType = value;
                  _filteredTransactions = _applyFilterAndSearch(_allTransactions);
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'all', child: Text('Semua')),
                const PopupMenuItem(value: 'income', child: Text('Pemasukan')),
                const PopupMenuItem(value: 'expense', child: Text('Pengeluaran')),
              ],
              icon: const Icon(Iconsax.filter),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allTransactions.isEmpty
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
              : _filteredTransactions.isEmpty
                  ? Center(
                      child: EmptyState(
                        icon: Iconsax.search_normal,
                        title: 'Transaksi tidak ditemukan',
                        subtitle: _searchQuery.isNotEmpty
                            ? 'Tidak ada transaksi yang sesuai dengan "$_searchQuery".'
                            : 'Tidak ada transaksi dengan filter yang dipilih.',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _loadTransactions(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredTransactions.length,
                        itemBuilder: (context, index) {
                          return TransactionListTile(
                            transaction: _filteredTransactions[index],
                            onDelete: () => _deleteTransaction(_filteredTransactions[index]),
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
