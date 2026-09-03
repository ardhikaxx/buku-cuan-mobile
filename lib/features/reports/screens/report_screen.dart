import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../transactions/services/transaction_service.dart';
import '../../debts/services/debt_service.dart';
import '../../receivables/services/receivable_service.dart';
import '../../capital/services/capital_service.dart';
import 'export_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedPeriod = 'Bulan Ini';
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _isLoading = true;

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _totalDebt = 0;
  double _totalReceivable = 0;
  double _totalCapital = 0;
  List<Map<String, dynamic>> _incomeByCategory = [];
  List<Map<String, dynamic>> _expenseByCategory = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<AppProvider>();
    if (provider.workspaceId == null) return;

    setState(() => _isLoading = true);

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
      case 'Bulan Ini':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'Custom':
        start = _customStart ?? DateTime(now.year, now.month, 1);
        end = _customEnd ?? now;
        break;
      default:
        start = DateTime(now.year, now.month, 1);
    }

    final txService = TransactionService();
    final debtService = DebtService();
    final receivableService = ReceivableService();
    final capitalService = CapitalService();

    final summary = await txService.getSummaryByType(provider.workspaceId!, start, end);
    final incomeByCat = await txService.getCategoryBreakdown(provider.workspaceId!, 'income', start, end);
    final expenseByCat = await txService.getCategoryBreakdown(provider.workspaceId!, 'expense', start, end);
    final totalDebt = await debtService.getTotalDebt(provider.workspaceId!);
    final totalReceivable = await receivableService.getTotalReceivable(provider.workspaceId!);
    final totalCapital = await capitalService.getTotalCapital(provider.workspaceId!);

    setState(() {
      _totalIncome = summary['income'] ?? 0;
      _totalExpense = summary['expense'] ?? 0;
      _totalDebt = totalDebt;
      _totalReceivable = totalReceivable;
      _totalCapital = totalCapital;
      _incomeByCategory = incomeByCat;
      _expenseByCategory = expenseByCat;
      _isLoading = false;
    });
  }

  Future<void> _selectCustomDate() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final netProfit = _totalIncome - _totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExportScreen()),
              );
            },
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Period Selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Custom'].map((period) {
                        final isSelected = _selectedPeriod == period;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(period),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedPeriod = period);
                              if (period == 'Custom') {
                                _selectCustomDate();
                              } else {
                                _loadData();
                              }
                            },
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary Cards
                  _SummaryCard(
                    label: 'Total Pemasukan',
                    amount: _totalIncome,
                    color: AppColors.income,
                  ),
                  const SizedBox(height: 8),
                  _SummaryCard(
                    label: 'Total Pengeluaran',
                    amount: _totalExpense,
                    color: AppColors.expense,
                  ),
                  const SizedBox(height: 8),
                  _SummaryCard(
                    label: 'Laba Bersih',
                    amount: netProfit,
                    color: netProfit >= 0 ? AppColors.success : AppColors.danger,
                  ),
                  const SizedBox(height: 8),
                  _SummaryCard(
                    label: 'Modal',
                    amount: _totalCapital,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Hutang',
                          amount: _totalDebt,
                          color: AppColors.debt,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Piutang',
                          amount: _totalReceivable,
                          color: AppColors.receivable,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Income Chart
                  if (_incomeByCategory.isNotEmpty) ...[
                    const Text('Pemasukan per Kategori',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sections: _incomeByCategory.asMap().entries.map((entry) {
                            final colors = [
                              AppColors.success, AppColors.primary, AppColors.income,
                              Colors.teal, Colors.green.shade300,
                            ];
                            final total = _incomeByCategory.fold<double>(
                                0, (sum, e) => sum + (e['amount'] as double));
                            final percentage = total > 0
                                ? ((entry.value['amount'] as double) / total * 100)
                                : 0.0;
                            return PieChartSectionData(
                              value: entry.value['amount'] as double,
                              title: '${percentage.toStringAsFixed(0)}%',
                              color: colors[entry.key % colors.length],
                              radius: 60,
                              titleStyle: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(_incomeByCategory.map((cat) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(cat['category'] as String,
                                  style: const TextStyle(fontSize: 13)),
                              const Spacer(),
                              Text(CurrencyFormatter.formatRupiah(cat['amount'] as double),
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ))),
                    const SizedBox(height: 20),
                  ],

                  // Expense Chart
                  if (_expenseByCategory.isNotEmpty) ...[
                    const Text('Pengeluaran per Kategori',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ...(_expenseByCategory.map((cat) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(cat['category'] as String,
                                  style: const TextStyle(fontSize: 13)),
                              const Spacer(),
                              Text(CurrencyFormatter.formatRupiah(cat['amount'] as double),
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ))),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            CurrencyFormatter.formatRupiah(amount),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
