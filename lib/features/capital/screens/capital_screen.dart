import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/constants/app_constants.dart';
import '../models/capital_model.dart';
import '../services/capital_service.dart';
import '../widgets/capital_list_tile.dart';
import '../widgets/capital_summary_card.dart';

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
                inputFormatters: [CurrencyInputFormatter()],
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

      final amount = CurrencyFormatter.parseRupiah(amountController.text);
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
                CapitalSummaryCard(totalCapital: _totalCapital),
                const SizedBox(height: 16),
                if (_capitals.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Belum ada catatan modal',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ...(_capitals.map((c) => CapitalListTile(capital: c))),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCapital,
        backgroundColor: AppColors.primary,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }
}
