import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../models/receivable_model.dart';
import '../services/receivable_service.dart';
import '../../reminders/services/reminder_service.dart';
import '../../reminders/models/reminder_model.dart';

class AddReceivableScreen extends StatefulWidget {
  final ReceivableModel? existingReceivable;

  const AddReceivableScreen({super.key, this.existingReceivable});

  @override
  State<AddReceivableScreen> createState() => _AddReceivableScreenState();
}

class _AddReceivableScreenState extends State<AddReceivableScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ReceivableService _receivableService = ReceivableService();
  final ReminderService _reminderService = ReminderService();

  DateTime _receivableDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _isSaving = false;
  bool _createReminder = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingReceivable != null) {
      _nameController.text = widget.existingReceivable!.name;
      _amountController.text = CurrencyFormatter.formatNumber(widget.existingReceivable!.amount);
      _descriptionController.text = widget.existingReceivable!.description ?? '';
      _receivableDate = widget.existingReceivable!.receivableDate;
      _dueDate = widget.existingReceivable!.dueDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isReceivableDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isReceivableDate ? _receivableDate : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        if (isReceivableDate) {
          _receivableDate = picked;
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

      final receivable = ReceivableModel(
        id: widget.existingReceivable?.id ?? FirebaseService.generateId(),
        workspaceId: provider.workspaceId!,
        name: _nameController.text.trim(),
        amount: amount,
        paidAmount: widget.existingReceivable?.paidAmount ?? 0,
        remainingAmount: amount - (widget.existingReceivable?.paidAmount ?? 0),
        receivableDate: _receivableDate,
        dueDate: _dueDate,
        status: widget.existingReceivable?.status ?? ReceivableStatus.unpaid,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdAt: widget.existingReceivable?.createdAt ?? now,
      );

      if (widget.existingReceivable != null) {
        await _receivableService.updateReceivable(receivable);
      } else {
        await _receivableService.addReceivable(receivable);
      }

      if (_createReminder && widget.existingReceivable == null) {
        final reminder = ReminderModel(
          id: FirebaseService.generateId(),
          workspaceId: provider.workspaceId!,
          type: 'receivable',
          referenceId: receivable.id,
          title: 'Piutang dari ${receivable.name}',
          amount: receivable.remainingAmount,
          dueDate: _dueDate,
          createdAt: now,
        );
        await _reminderService.addReminder(reminder);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Piutang berhasil disimpan'),
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
        title: Text(widget.existingReceivable != null ? 'Edit Piutang' : 'Tambah Piutang'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nama Pelanggan', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Contoh: Andi, PT Sejahtera'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Masukkan nama pelanggan';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const Text('Nominal Piutang', style: TextStyle(fontWeight: FontWeight.w600)),
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

              const Text('Tanggal Piutang', style: TextStyle(fontWeight: FontWeight.w600)),
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
                  child: Text(DateFormatter.formatDate(_receivableDate)),
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
                decoration: const InputDecoration(hintText: 'Keterangan piutang...'),
              ),
              const SizedBox(height: 16),

              if (widget.existingReceivable == null)
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
