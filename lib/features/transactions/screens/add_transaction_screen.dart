import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final String initialType;

  const AddTransactionScreen({super.key, this.initialType = 'income'});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final TransactionService _transactionService = TransactionService();

  late String _type;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMethod = 'Tunai';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<String> get _categories =>
      _type == 'income' ? AppConstants.defaultIncomeCategories : AppConstants.defaultExpenseCategories;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final provider = context.read<AppProvider>();
      if (provider.workspaceId == null) return;

      final amount = double.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
      final now = DateTime.now();

      final transaction = TransactionModel(
        id: FirebaseService.generateId(),
        workspaceId: provider.workspaceId!,
        type: _type,
        amount: amount,
        categoryId: _selectedCategoryId ?? '',
        categoryName: _selectedCategoryName ?? _categories.first,
        date: _selectedDate,
        description: _descriptionController.text.trim(),
        paymentMethod: _selectedPaymentMethod,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await _transactionService.addTransaction(transaction);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_type == 'income' ? 'Pemasukan berhasil disimpan' : 'Pengeluaran berhasil disimpan'),
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
        title: Text(_type == 'income' ? 'Uang Masuk' : 'Uang Keluar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = 'income';
                          _selectedCategoryId = null;
                          _selectedCategoryName = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _type == 'income' ? AppColors.income : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Uang Masuk',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _type == 'income' ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = 'expense';
                          _selectedCategoryId = null;
                          _selectedCategoryName = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _type == 'expense' ? AppColors.expense : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Uang Keluar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _type == 'expense' ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Amount
              const Text('Nominal', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  hintText: '0',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Masukkan nominal';
                  final amount = double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
                  if (amount == null || amount <= 0) return 'Nominal tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategoryName,
                isExpanded: true,
                decoration: const InputDecoration(),
                hint: const Text('Pilih kategori'),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryName = value;
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) => value == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 16),

              // Date
              const Text('Tanggal', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    DateFormatter.formatDate(_selectedDate),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              const Text('Keterangan', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(hintText: 'Contoh: Penjualan nasi goreng'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Masukkan keterangan';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Payment Method
              const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                isExpanded: true,
                decoration: const InputDecoration(),
                items: AppConstants.paymentMethods.map((method) {
                  return DropdownMenuItem(value: method, child: Text(method));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedPaymentMethod = value);
                },
              ),
              const SizedBox(height: 16),

              // Notes
              const Text('Catatan (opsional)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Catatan tambahan...'),
              ),
              const SizedBox(height: 24),

              // Save Button
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
