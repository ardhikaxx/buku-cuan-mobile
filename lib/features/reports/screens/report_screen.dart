import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../services/report_service.dart';
import '../widgets/report_category_breakdown.dart';
import '../widgets/report_filter_bar.dart';
import '../widgets/report_summary_card.dart';
import 'export_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _reportService = ReportService();
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

      final data = await _reportService.getReportData(
        workspaceId: provider.workspaceId!,
        start: start,
        end: end,
      );

      if (mounted) {
        setState(() {
          _totalIncome = data['totalIncome'] ?? 0.0;
          _totalExpense = data['totalExpense'] ?? 0.0;
          _totalDebt = data['totalDebt'] ?? 0.0;
          _totalReceivable = data['totalReceivable'] ?? 0.0;
          _totalCapital = data['totalCapital'] ?? 0.0;
          _incomeByCategory = data['incomeByCategory'] ?? [];
          _expenseByCategory = data['expenseByCategory'] ?? [];
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
                  ReportFilterBar(
                    selectedPeriod: _selectedPeriod,
                    activeDateRangeText: _getActiveDateRangeText(),
                    onPeriodSelected: (period) {
                      if (_selectedPeriod == period && period != 'Kustom') return;
                      setState(() => _selectedPeriod = period);
                      if (period == 'Kustom') {
                        _selectCustomDate();
                      } else {
                        _loadData();
                      }
                    },
                    onCustomDateTap: _selectCustomDate,
                  ),
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
                  ReportSummaryCard(
                    label: 'Total Pemasukan',
                    amount: _totalIncome,
                    color: AppColors.income,
                    icon: Iconsax.money_recive,
                  ),
                  const SizedBox(height: 8),
                  ReportSummaryCard(
                    label: 'Total Pengeluaran',
                    amount: _totalExpense,
                    color: AppColors.expense,
                    icon: Iconsax.money_send,
                  ),
                  const SizedBox(height: 8),
                  ReportSummaryCard(
                    label: 'Laba Bersih',
                    amount: netProfit,
                    color: netProfit >= 0 ? AppColors.income : AppColors.expense,
                    icon: netProfit >= 0 ? Iconsax.trend_up : Iconsax.trend_down,
                    badge: netProfit >= 0 ? 'Surplus' : 'Defisit',
                  ),
                  const SizedBox(height: 8),
                  ReportSummaryCard(
                    label: 'Total Modal Usaha',
                    amount: _totalCapital,
                    color: const Color(0xFF8E24AA),
                    icon: Iconsax.bank,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ReportSummaryCard(
                          label: 'Hutang',
                          amount: _totalDebt,
                          color: AppColors.debt,
                          icon: Iconsax.card_send,
                          isVertical: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ReportSummaryCard(
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
                    ReportCategoryBreakdown(
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
                    ReportCategoryBreakdown(
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
}
