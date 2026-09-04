import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../models/debt_model.dart';
import '../services/debt_service.dart';
import '../../reminders/services/reminder_service.dart';
import '../../reminders/models/reminder_model.dart';

class AddDebtScreen extends StatefulWidget {
  final DebtModel? existingDebt;

  const AddDebtScreen({super.key, this.existingDebt});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final DebtService _debtService = DebtService();
  final ReminderService _reminderService = ReminderService();

  DateTime _debtDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _isSaving = false;
  bool _createReminder = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingDebt != null) {
      _nameController.text = widget.existingDebt!.name;
      _amountController.text = CurrencyFormatter.formatNumber(widget.existingDebt!.amount);
      _descriptionController.text = widget.existingDebt!.description ?? '';
      _debtDate = widget.existingDebt!.debtDate;
      _dueDate = widget.existingDebt!.dueDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isDebtDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDebtDate ? _debtDate : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        if (isDebtDate) {
          _debtDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final provider = context.read<AppProvider>();
      if (provider.workspaceId == null) return;

      final amount = CurrencyFormatter.parseRupiah(_amountController.text);
      final now = DateTime.now();

      final debt = DebtModel(
        id: widget.existingDebt?.id ?? FirebaseService.generateId(),
        workspaceId: provider.workspaceId!,
        name: _nameController.text.trim(),
        amount: amount,
        paidAmount: widget.existingDebt?.paidAmount ?? 0,
        remainingAmount: amount - (widget.existingDebt?.paidAmount ?? 0),
        debtDate: _debtDate,
        dueDate: _dueDate,
        status: widget.existingDebt?.status ?? DebtStatus.unpaid,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdAt: widget.existingDebt?.createdAt ?? now,
      );

      if (widget.existingDebt != null) {
        await _debtService.updateDebt(debt);
      } else {
        await _debtService.addDebt(debt);
      }

      if (_createReminder && widget.existingDebt == null) {
        final reminder = ReminderModel(
          id: FirebaseService.generateId(),
          workspaceId: provider.workspaceId!,
          type: 'debt',
          referenceId: debt.id,
          title: 'Bayar hutang kepada ${debt.name}',
          amount: debt.remainingAmount,
          dueDate: _dueDate,
          createdAt: now,
        );
        await _reminderService.addReminder(reminder);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hutang berhasil disimpan'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingDebt != null ? 'Edit Hutang' : 'Tambah Hutang'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nama Pihak', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Contoh: Budi, Toko Maju'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Masukkan nama pihak';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const Text('Nominal Hutang', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  hintText: '0',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Masukkan nominal';
                  final amount = CurrencyFormatter.parseRupiah(value);
                  if (amount <= 0) return 'Nominal tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const Text('Tanggal Hutang', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(DateFormatter.formatDate(_debtDate)),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Tanggal Jatuh Tempo', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(false),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(DateFormatter.formatDate(_dueDate)),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Keterangan', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(hintText: 'Keterangan hutang...'),
              ),
              const SizedBox(height: 16),

              if (widget.existingDebt == null)
                CheckboxListTile(
                  value: _createReminder,
                  onChanged: (value) => setState(() => _createReminder = value ?? true),
                  title: const Text('Buat reminder jatuh tempo'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
