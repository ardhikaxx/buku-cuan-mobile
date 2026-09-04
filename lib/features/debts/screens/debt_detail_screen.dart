import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/firebase_service.dart';
import '../models/debt_model.dart';
import '../services/debt_service.dart';

class DebtDetailScreen extends StatefulWidget {
  final DebtModel debt;

  const DebtDetailScreen({super.key, required this.debt});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  final DebtService _debtService = DebtService();
  late DebtModel _debt;

  @override
  void initState() {
    super.initState();
    _debt = widget.debt;
  }

  Future<void> _makePayment() async {
    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bayar Hutang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sisa hutang: ${CurrencyFormatter.formatRupiah(_debt.remainingAmount)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                hintText: '0',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              final amount = CurrencyFormatter.parseRupiah(controller.text);
              if (amount > 0) {
                Navigator.pop(context, amount);
              }
            },
            child: const Text('Bayar'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _debtService.makePayment(_debt.id, result);
      final doc = await FirebaseService.firestore.collection('debts').doc(_debt.id).get();
      setState(() {
        _debt = DebtModel.fromFirestore(doc);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran berhasil'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _deleteDebt() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Hutang'),
        content: const Text('Apakah Anda yakin ingin menghapus hutang ini?'),
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
      await _debtService.deleteDebt(_debt.id);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _debt.status == DebtStatus.paid
        ? AppColors.success
        : _debt.status == DebtStatus.partial
            ? AppColors.warning
            : AppColors.danger;

    final statusText = _debt.status == DebtStatus.paid
        ? 'Lunas'
        : _debt.status == DebtStatus.partial
            ? 'Sebagian'
            : 'Belum Lunas';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Hutang'),
        actions: [
          IconButton(
            onPressed: _deleteDebt,
            icon: const Icon(Iconsax.trash, color: AppColors.danger),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text(
                  _debt.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  CurrencyFormatter.formatRupiah(_debt.remainingAmount),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'dari ${CurrencyFormatter.formatRupiah(_debt.amount)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Tanggal Hutang', value: DateFormatter.formatDate(_debt.debtDate)),
          _InfoRow(label: 'Jatuh Tempo', value: DateFormatter.formatDate(_debt.dueDate)),
          _InfoRow(label: 'Sudah Dibayar', value: CurrencyFormatter.formatRupiah(_debt.paidAmount)),
          if (_debt.description != null && _debt.description!.isNotEmpty)
            _InfoRow(label: 'Keterangan', value: _debt.description!),
          const SizedBox(height: 24),
          if (_debt.status != DebtStatus.paid)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _makePayment,
                child: const Text('Bayar Hutang'),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
