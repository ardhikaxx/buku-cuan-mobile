import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
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
  DateTime _currentStartDate = DateTime.now();
  DateTime _currentEndDate = DateTime.now();
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
    if (provider.workspaceId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      DateTime start;
      DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      switch (_selectedPeriod) {
        case 'Hari Ini':
          start = DateTime(now.year, now.month, now.day, 0, 0, 0);
          end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          break;
        case 'Minggu Ini':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0, 0);
          end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          break;
        case 'Bulan Ini':
          start = DateTime(now.year, now.month, 1, 0, 0, 0);
          final lastDay = DateTime(now.year, now.month + 1, 0);
          end = DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59, 999);
          break;
        case 'Bulan Lalu':
          final prevMonth = DateTime(now.year, now.month - 1, 1);
          start = DateTime(prevMonth.year, prevMonth.month, 1, 0, 0, 0);
          final lastDayPrev = DateTime(prevMonth.year, prevMonth.month + 1, 0);
          end = DateTime(lastDayPrev.year, lastDayPrev.month, lastDayPrev.day, 23, 59, 59, 999);
          break;
        case 'Tahun Ini':
          start = DateTime(now.year, 1, 1, 0, 0, 0);
          end = DateTime(now.year, 12, 31, 23, 59, 59, 999);
          break;
        case 'Kustom':
          start = _customStart != null
              ? DateTime(_customStart!.year, _customStart!.month, _customStart!.day, 0, 0, 0)
              : DateTime(now.year, now.month, 1, 0, 0, 0);
          end = _customEnd != null
              ? DateTime(_customEnd!.year, _customEnd!.month, _customEnd!.day, 23, 59, 59, 999)
              : DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          break;
        default:
          start = DateTime(now.year, now.month, 1, 0, 0, 0);
          end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      }

      _currentStartDate = start;
      _currentEndDate = end;

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

      if (mounted) {
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
    } catch (e) {
      debugPrint('Error loading report data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectCustomDate() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: now,
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
      });
      _loadData();
    } else if (_customStart == null || _customEnd == null) {
      setState(() {
        _customStart = DateTime(now.year, now.month, 1);
        _customEnd = now;
      });
      _loadData();
    }
  }

  String _getActiveDateRangeText() {
    if (_selectedPeriod == 'Hari Ini') {
      return DateFormatter.formatDate(_currentStartDate);
    } else if (_selectedPeriod == 'Bulan Ini' || _selectedPeriod == 'Bulan Lalu') {
      return '${DateFormatter.formatMonthYear(_currentStartDate)} (${DateFormatter.formatShortDate(_currentStartDate)} - ${DateFormatter.formatShortDate(_currentEndDate)})';
    } else {
      return '${DateFormatter.formatDate(_currentStartDate)} - ${DateFormatter.formatDate(_currentEndDate)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final netProfit = _totalIncome - _totalExpense;
    final bool hasAnyData = _totalIncome > 0 ||
        _totalExpense > 0 ||
        _incomeByCategory.isNotEmpty ||
        _expenseByCategory.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExportScreen()),
              );
            },
            icon: const Icon(Iconsax.document_download),
            tooltip: 'Export Laporan',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  _buildFilterSection(),
                  const SizedBox(height: 14),

                  // Summary Section Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Iconsax.status, size: 18, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Ringkasan Keuangan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Summary Cards
                  _SummaryCard(
                    label: 'Total Pemasukan',
                    amount: _totalIncome,
                    color: AppColors.income,
                    icon: Iconsax.money_recive,
                  ),
                  const SizedBox(height: 8),
                  _SummaryCard(
                    label: 'Total Pengeluaran',
                    amount: _totalExpense,
                    color: AppColors.expense,
                    icon: Iconsax.money_send,
                  ),
                  const SizedBox(height: 8),
                  _SummaryCard(
                    label: 'Laba Bersih',
                    amount: netProfit,
                    color: netProfit >= 0 ? AppColors.income : AppColors.expense,
                    icon: netProfit >= 0 ? Iconsax.trend_up : Iconsax.trend_down,
                    badge: netProfit >= 0 ? 'Surplus' : 'Defisit',
                  ),
                  const SizedBox(height: 8),
                  _SummaryCard(
                    label: 'Total Modal Usaha',
                    amount: _totalCapital,
                    color: const Color(0xFF8E24AA),
                    icon: Iconsax.bank,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Hutang',
                          amount: _totalDebt,
                          color: AppColors.debt,
                          icon: Iconsax.card_send,
                          isVertical: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Piutang',
                          amount: _totalReceivable,
                          color: AppColors.receivable,
                          icon: Iconsax.card_receive,
                          isVertical: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Empty state if no data for this period
                  if (!hasAnyData)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const EmptyState(
                        icon: Iconsax.document_text_1,
                        title: 'Tidak Ada Aktivitas Transaksi',
                        subtitle: 'Belum ada pemasukan atau pengeluaran yang tercatat pada periode ini.',
                      ),
                    ),

                  // Income Category Breakdown
                  if (_incomeByCategory.isNotEmpty) ...[
                    _buildCategoryBreakdownCard(
                      title: 'Pemasukan per Kategori',
                      icon: Iconsax.money_recive,
                      headerColor: AppColors.income,
                      items: _incomeByCategory,
                      palette: const [
                        AppColors.primary,
                        Color(0xFF00AED6),
                        Color(0xFFFF6D00),
                        Color(0xFF8E24AA),
                        Color(0xFF00880C),
                        Color(0xFFEE2737),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Expense Category Breakdown
                  if (_expenseByCategory.isNotEmpty) ...[
                    _buildCategoryBreakdownCard(
                      title: 'Pengeluaran per Kategori',
                      icon: Iconsax.money_send,
                      headerColor: AppColors.expense,
                      items: _expenseByCategory,
                      palette: const [
                        Color(0xFFEE2737),
                        Color(0xFFFF6D00),
                        Color(0xFFD97706),
                        Color(0xFF8E24AA),
                        Color(0xFFE91E63),
                        Color(0xFF5C6BC0),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.filter_edit, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Filter Periode',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_selectedPeriod == 'Kustom')
                InkWell(
                  onTap: _selectCustomDate,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Iconsax.edit_2, size: 13, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Ubah Rentang',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterPill('Hari Ini', Iconsax.calendar_1),
                _buildFilterPill('Minggu Ini', Iconsax.calendar_2),
                _buildFilterPill('Bulan Ini', Iconsax.calendar),
                _buildFilterPill('Bulan Lalu', Iconsax.calendar_edit),
                _buildFilterPill('Tahun Ini', Iconsax.calendar_circle),
                _buildFilterPill('Kustom', Iconsax.calendar_search),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectedPeriod == 'Kustom' ? _selectCustomDate : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8EA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.calendar_tick, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Menampilkan data periode:',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _getActiveDateRangeText(),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006C0E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedPeriod == 'Kustom')
                    const Icon(Iconsax.arrow_right_3, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String period, IconData icon) {
    final isSelected = _selectedPeriod == period;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          if (_selectedPeriod == period && period != 'Kustom') return;
          setState(() => _selectedPeriod = period);
          if (period == 'Kustom') {
            _selectCustomDate();
          } else {
            _loadData();
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                period,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownCard({
    required String title,
    required IconData icon,
    required Color headerColor,
    required List<Map<String, dynamic>> items,
    required List<Color> palette,
  }) {
    final total = items.fold<double>(0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: headerColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (total > 0) ...[
            SizedBox(
              height: 170,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: items.asMap().entries.map((entry) {
                    final amount = (entry.value['amount'] as num?)?.toDouble() ?? 0.0;
                    final percentage = total > 0 ? (amount / total * 100) : 0.0;
                    final color = palette[entry.key % palette.length];
                    return PieChartSectionData(
                      value: amount,
                      title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                      color: color,
                      radius: 46,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          ...items.asMap().entries.map((entry) {
            final color = palette[entry.key % palette.length];
            final amount = (entry.value['amount'] as num?)?.toDouble() ?? 0.0;
            final category = entry.value['category'] as String? ?? 'Lainnya';
            final percentage = total > 0 ? (amount / total * 100) : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.formatRupiah(amount),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData? icon;
  final String? badge;
  final bool isVertical;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    this.icon,
    this.badge,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isVertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 14, color: color),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.formatRupiah(amount),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      CurrencyFormatter.formatRupiah(amount),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
