import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/constants/app_constants.dart';
import '../models/capital_model.dart';
import '../services/capital_service.dart';

class CapitalScreen extends StatefulWidget {
  const CapitalScreen({super.key});

  @override
  State<CapitalScreen> createState() => _CapitalScreenState();
}

class _CapitalScreenState extends State<CapitalScreen> {
  final CapitalService _capitalService = CapitalService();
  List<CapitalModel> _capitals = [];
  bool _isLoading = true;
  double _totalCapital = 0;

  @override
  void initState() {
    super.initState();
    _loadCapital();
  }

  void _loadCapital() {
    final provider = context.read<AppProvider>();
    if (provider.workspaceId == null) return;

    _capitalService.getCapital(provider.workspaceId!).listen((capitals) async {
      final total = await _capitalService.getTotalCapital(provider.workspaceId!);
      setState(() {
        _capitals = capitals;
        _totalCapital = total;
        _isLoading = false;
      });
    });
  }

  Future<void> _addCapital() async {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedType = AppConstants.capitalTypes.first;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Modal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                isExpanded: true,
                items: AppConstants.capitalTypes.map((t) {
                  return DropdownMenuItem(value: t, child: Text(AppConstants.capitalTypeLabels[t] ?? t));
                }).toList(),
                onChanged: (v) => setDialogState(() => selectedType = v!),
                decoration: const InputDecoration(labelText: 'Jenis Modal'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Keterangan'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final provider = context.read<AppProvider>();
      if (provider.workspaceId == null) return;

      final amountText = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (amountText.isEmpty) return;
      final amount = double.parse(amountText);
      if (amount <= 0) return;

      final capital = CapitalModel(
        id: FirebaseService.generateId(),
        workspaceId: provider.workspaceId!,
        type: selectedType,
        amount: amount,
        date: selectedDate,
        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _capitalService.addCapital(capital);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modal')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('Total Modal',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatRupiah(_totalCapital),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_capitals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Belum ada catatan modal',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ...(_capitals.map((c) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            c.isWithdrawal ? Icons.arrow_upward : Icons.arrow_downward,
                            color: c.isWithdrawal ? AppColors.danger : AppColors.success,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppConstants.capitalTypeLabels[c.type] ?? c.type,
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600)),
                                Text(DateFormatter.formatDate(c.date),
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Text(
                            '${c.isWithdrawal ? '-' : '+'}${CurrencyFormatter.formatRupiah(c.amount)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: c.isWithdrawal ? AppColors.danger : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ))),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCapital,
        backgroundColor: const Color(0xFF2C3E50),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
