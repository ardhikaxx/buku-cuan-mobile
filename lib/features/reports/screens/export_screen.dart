import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../transactions/services/transaction_service.dart';
import '../../debts/services/debt_service.dart';
import '../../receivables/services/receivable_service.dart';
import '../../capital/services/capital_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  String _selectedPeriod = 'Bulan Ini';
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Data')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Periode', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...(['Hari Ini', 'Minggu Ini', 'Bulan Ini'].map((period) {
              return RadioListTile<String>(
                title: Text(period),
                value: period,
                groupValue: _selectedPeriod,
                onChanged: (v) => setState(() => _selectedPeriod = v!),
                activeColor: AppColors.primary,
              );
            })),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : () => _exportPDF(),
                icon: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isExporting ? null : () => _exportExcel(),
                icon: const Icon(Icons.table_chart),
                label: const Text('Export Excel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadExportData() async {
    final provider = context.read<AppProvider>();
    if (provider.workspaceId == null) return {};

    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (_selectedPeriod) {
      case 'Hari Ini':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'Minggu Ini':
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      default:
        start = DateTime(now.year, now.month, 1);
    }

    final txService = TransactionService();
    final debtService = DebtService();
    final receivableService = ReceivableService();
    final capitalService = CapitalService();

    final summary = await txService.getSummaryByType(provider.workspaceId!, start, end);
    final transactions = await txService.getTransactions(provider.workspaceId!).first;
    final debts = await debtService.getDebts(provider.workspaceId!).first;
    final receivables = await receivableService.getReceivables(provider.workspaceId!).first;
    final capitals = await capitalService.getCapital(provider.workspaceId!).first;
    final totalDebt = await debtService.getTotalDebt(provider.workspaceId!);
    final totalReceivable = await receivableService.getTotalReceivable(provider.workspaceId!);

    return {
      'income': summary['income'] ?? 0,
      'expense': summary['expense'] ?? 0,
      'netProfit': (summary['income'] ?? 0) - (summary['expense'] ?? 0),
      'totalDebt': totalDebt,
      'totalReceivable': totalReceivable,
      'transactions': transactions,
      'debts': debts,
      'receivables': receivables,
      'capitals': capitals,
      'period': _selectedPeriod,
    };
  }

  Future<void> _exportPDF() async {
    setState(() => _isExporting = true);

    try {
      final data = await _loadExportData();
      if (data.isEmpty || !mounted) return;

      final pdf = pw.Document();
      final businessName = context.read<AppProvider>().userName ?? 'Buku Cuan';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('Laporan Keuangan - $businessName',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Text('Periode: ${data['period']}'),
            pw.SizedBox(height: 16),
            pw.Text('Ringkasan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _pdfRow('Total Pemasukan', CurrencyFormatter.formatRupiah(data['income'])),
            _pdfRow('Total Pengeluaran', CurrencyFormatter.formatRupiah(data['expense'])),
            _pdfRow('Laba Bersih', CurrencyFormatter.formatRupiah(data['netProfit'])),
            _pdfRow('Hutang', CurrencyFormatter.formatRupiah(data['totalDebt'])),
            _pdfRow('Piutang', CurrencyFormatter.formatRupiah(data['totalReceivable'])),
            pw.SizedBox(height: 20),
            pw.Text('Transaksi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            ...((data['transactions'] as List).take(50).map((t) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(t.description, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Text(
                        '${t.isIncome ? '+' : '-'}${CurrencyFormatter.formatRupiah(t.amount)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: t.isIncome ? PdfColors.green : PdfColors.red,
                        ),
                      ),
                    ],
                  ),
                ))),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export PDF: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);

    try {
      final data = await _loadExportData();
      if (data.isEmpty) return;

      var excel = Excel.createExcel();

      // Summary Sheet
      excel.rename(excel.getDefaultSheet()!, 'Ringkasan');
      var summarySheet = excel['Ringkasan'];
      summarySheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Laporan Keuangan');
      summarySheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('Total Pemasukan');
      summarySheet.cell(CellIndex.indexByString('B3')).value = TextCellValue(CurrencyFormatter.formatRupiah(data['income']));
      summarySheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Total Pengeluaran');
      summarySheet.cell(CellIndex.indexByString('B4')).value = TextCellValue(CurrencyFormatter.formatRupiah(data['expense']));
      summarySheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Laba Bersih');
      summarySheet.cell(CellIndex.indexByString('B5')).value = TextCellValue(CurrencyFormatter.formatRupiah(data['netProfit']));

      // Transactions Sheet
      var txSheet = excel['Transaksi'];
      txSheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Tanggal');
      txSheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Tipe');
      txSheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Kategori');
      txSheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Keterangan');
      txSheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('Nominal');

      int row = 2;
      for (final tx in data['transactions'] as List) {
        txSheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(DateFormatter.formatDate(tx.date));
        txSheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue(tx.isIncome ? 'Pemasukan' : 'Pengeluaran');
        txSheet.cell(CellIndex.indexByString('C$row')).value = TextCellValue(tx.categoryName);
        txSheet.cell(CellIndex.indexByString('D$row')).value = TextCellValue(tx.description);
        txSheet.cell(CellIndex.indexByString('E$row')).value = TextCellValue(CurrencyFormatter.formatRupiah(tx.amount));
        row++;
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/laporan_buku_cuan.xlsx');
      await file.writeAsBytes(excel.encode()!);
      await Share.shareXFiles([XFile(file.path)], text: 'Laporan Buku Cuan');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export Excel: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }
}
