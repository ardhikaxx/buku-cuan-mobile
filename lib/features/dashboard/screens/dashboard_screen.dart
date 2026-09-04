import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/screens/add_transaction_screen.dart';
import '../../transactions/screens/transaction_list_screen.dart';
import '../../transactions/widgets/transaction_list_tile.dart';
import '../../debts/screens/add_debt_screen.dart';
import '../../receivables/screens/add_receivable_screen.dart';
import '../../capital/screens/capital_screen.dart';
import '../../reminders/screens/reminder_screen.dart';
import '../../reports/screens/export_screen.dart';
import '../../settings/screens/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  Map<String, double> _summary = {};
  List<Map<String, dynamic>> _cashFlowData = [];
  List<TransactionModel> _recentTransactions = [];
  bool _isLoading = true;
  bool _isCashFlowLoading = false;
  bool _isBalanceVisible = true;
  String _cashFlowFilter = '7_days';

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

    try {
      final summary = await _dashboardService.getSummary(provider.workspaceId!);
      final cashFlowData =
          await _dashboardService.getCashFlowData(provider.workspaceId!, _cashFlowFilter);
      final recentTransactions =
          await _dashboardService.getRecentTransactions(provider.workspaceId!, 5);

      if (mounted) {
        setState(() {
          _summary = summary;
          _cashFlowData = cashFlowData;
          _recentTransactions = recentTransactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCashFlowOnly() async {
    final provider = context.read<AppProvider>();
    if (provider.workspaceId == null) return;

    setState(() => _isCashFlowLoading = true);
    try {
      final cashFlowData =
          await _dashboardService.getCashFlowData(provider.workspaceId!, _cashFlowFilter);
      if (mounted) {
        setState(() {
          _cashFlowData = cashFlowData;
          _isCashFlowLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCashFlowLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildBalanceCard(),
              const SizedBox(height: 14),
              _buildNetProfitCard(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildCashFlowChart(),
              const SizedBox(height: 20),
              _buildRecentTransactions(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final provider = context.watch<AppProvider>();
    final businessName = provider.userName ?? 'Buku Cuan';
    final initial = businessName.isNotEmpty ? businessName[0].toUpperCase() : 'B';

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00880C), Color(0xFF00AA13)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00AA13).withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'Halo, Selamat Datang',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text('👋', style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                businessName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Iconsax.refresh_2, color: Color(0xFF616161), size: 20),
            onPressed: _loadData,
            tooltip: 'Perbarui Data',
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    final balance = _summary['balance'] ?? 0;
    final totalIncome = _summary['totalIncome'] ?? 0;
    final totalExpense = _summary['totalExpense'] ?? 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF006C0E),
            Color(0xFF00880C),
            Color(0xFF00AA13),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00AA13).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: 80,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Iconsax.wallet_3, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'TOTAL SALDO USAHA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isBalanceVisible ? Iconsax.eye : Iconsax.eye_slash,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _isBalanceVisible ? CurrencyFormatter.formatRupiah(balance) : 'Rp ••••••••',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.income.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Iconsax.money_recive, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Uang Masuk',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                  Text(
                                    _isBalanceVisible
                                        ? CurrencyFormatter.formatRupiahShort(totalIncome)
                                        : 'Rp ••••',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 28,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.expense.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Iconsax.money_send, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Uang Keluar',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                  Text(
                                    _isBalanceVisible
                                        ? CurrencyFormatter.formatRupiahShort(totalExpense)
                                        : 'Rp ••••',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetProfitCard() {
    final netProfit = _summary['netProfit'] ?? 0;
    final isProfit = netProfit >= 0;
    final color = isProfit ? AppColors.income : AppColors.expense;
    final bgColor = isProfit ? const Color(0xFFE8F8EA) : const Color(0xFFFFEAEA);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isProfit ? Iconsax.trend_up : Iconsax.trend_down,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Laba Bersih Usaha',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.formatRupiah(netProfit),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isProfit ? Iconsax.tick_circle : Iconsax.info_circle,
                  size: 13,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  isProfit ? 'Surplus' : 'Defisit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Icon(Iconsax.flash_1, size: 20, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'Aksi Cepat',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _GojekServiceItem(
                icon: Iconsax.money_recive,
                label: 'Uang Masuk',
                iconColor: const Color(0xFF00880C),
                backgroundColor: const Color(0xFFE8F8EA),
                onTap: () => _navigateToAddTransaction('income'),
              ),
              _GojekServiceItem(
                icon: Iconsax.money_send,
                label: 'Uang Keluar',
                iconColor: const Color(0xFFEE2737),
                backgroundColor: const Color(0xFFFFEAEA),
                onTap: () => _navigateToAddTransaction('expense'),
              ),
              _GojekServiceItem(
                icon: Iconsax.card_send,
                label: 'Hutang',
                iconColor: const Color(0xFFFF6D00),
                backgroundColor: const Color(0xFFFFF3E0),
                onTap: () => _navigateToAddDebt(),
              ),
              _GojekServiceItem(
                icon: Iconsax.card_receive,
                label: 'Piutang',
                iconColor: const Color(0xFF00AED6),
                backgroundColor: const Color(0xFFE0F7FA),
                onTap: () => _navigateToAddReceivable(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _GojekServiceItem(
                icon: Iconsax.bank,
                label: 'Modal Usaha',
                iconColor: const Color(0xFF8E24AA),
                backgroundColor: const Color(0xFFF3E5F5),
                onTap: () => _navigateTo(const CapitalScreen()),
              ),
              _GojekServiceItem(
                icon: Iconsax.notification_bing,
                label: 'Pengingat',
                iconColor: const Color(0xFFD97706),
                backgroundColor: const Color(0xFFFEF3C7),
                onTap: () => _navigateTo(const ReminderScreen()),
              ),
              _GojekServiceItem(
                icon: Iconsax.document_download,
                label: 'Export Data',
                iconColor: const Color(0xFF4338CA),
                backgroundColor: const Color(0xFFE0E7FF),
                onTap: () => _navigateTo(const ExportScreen()),
              ),
              _GojekServiceItem(
                icon: Iconsax.setting_2,
                label: 'Pengaturan',
                iconColor: const Color(0xFF616161),
                backgroundColor: const Color(0xFFF0F0F0),
                onTap: () => _navigateTo(const SettingsScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowChart() {
    final bool hasData = _cashFlowData.isNotEmpty &&
        _cashFlowData.any((d) => ((d['income'] as double?) ?? 0) > 0 || ((d['expense'] as double?) ?? 0) > 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Iconsax.chart_21, size: 20, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Arus Kas Usaha',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F8),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPeriodFilterItem('7 Hari', '7_days'),
                    _buildPeriodFilterItem('Bulan', 'monthly'),
                    _buildPeriodFilterItem('Tahun', 'yearly'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _cashFlowFilter == 'monthly'
                    ? 'Tahun ${DateTime.now().year}'
                    : _cashFlowFilter == 'yearly'
                        ? '5 Tahun Terakhir'
                        : '7 Hari Terakhir',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.income,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Masuk', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  const SizedBox(width: 10),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.expense,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Keluar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isCashFlowLoading)
            const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: EmptyState(
                  icon: Iconsax.chart_21,
                  title: 'Belum ada aktivitas arus kas',
                  subtitle: _cashFlowFilter == 'monthly'
                      ? 'Grafik transaksi bulanan tahun ${DateTime.now().year} akan muncul setelah ada pemasukan atau pengeluaran.'
                      : _cashFlowFilter == 'yearly'
                          ? 'Grafik transaksi tahunan akan muncul setelah ada pemasukan atau pengeluaran.'
                          : 'Grafik transaksi 7 hari terakhir akan muncul setelah Anda mencatat pemasukan atau pengeluaran.',
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxY(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final index = group.x;
                        if (index < 0 || index >= _cashFlowData.length) return null;
                        final item = _cashFlowData[index];
                        final label = item['label'] ?? '';
                        final isIncome = rodIndex == 0;
                        final typeLabel = isIncome ? 'Masuk' : 'Keluar';
                        return BarTooltipItem(
                          '$label\n$typeLabel: ${CurrencyFormatter.formatRupiah(rod.toY)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _cashFlowData.length) {
                            final label = _cashFlowData[index]['label'] as String? ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: _cashFlowFilter == 'monthly' ? 8.5 : 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: _cashFlowData.asMap().entries.map((entry) {
                    final income = (entry.value['income'] as double?) ?? 0;
                    final expense = (entry.value['expense'] as double?) ?? 0;
                    final double rodWidth = _cashFlowFilter == 'monthly'
                        ? 5.0
                        : _cashFlowFilter == 'yearly'
                            ? 14.0
                            : 9.0;
                    return BarChartGroupData(
                      x: entry.key,
                      barsSpace: 2,
                      barRods: [
                        BarChartRodData(
                          toY: income,
                          color: AppColors.income,
                          width: rodWidth,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: expense,
                          color: AppColors.expense,
                          width: rodWidth,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilterItem(String label, String value) {
    final isSelected = _cashFlowFilter == value;
    return InkWell(
      onTap: () {
        if (_cashFlowFilter != value) {
          setState(() {
            _cashFlowFilter = value;
          });
          _loadCashFlowOnly();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  double _getMaxY() {
    double max = 0;
    for (final data in _cashFlowData) {
      final income = (data['income'] as num?)?.toDouble() ?? 0.0;
      final expense = (data['expense'] as num?)?.toDouble() ?? 0.0;
      if (income > max) max = income;
      if (expense > max) max = expense;
    }
    return max > 0 ? max * 1.2 : 100000;
  }

  Widget _buildRecentTransactions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Iconsax.clock, size: 20, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Transaksi Terbaru',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _navigateTo(const TransactionListScreen()),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Iconsax.arrow_right_3,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentTransactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: EmptyState(
                  icon: Iconsax.receipt_text,
                  title: 'Belum ada transaksi',
                  subtitle: 'Mulai catat pemasukan atau pengeluaran usaha Anda.',
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentTransactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final transaction = _recentTransactions[index];
                return TransactionListTile(
                  transaction: transaction,
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _navigateTo(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    _loadData();
  }

  void _navigateToAddTransaction(String type) =>
      _navigateTo(AddTransactionScreen(initialType: type));

  void _navigateToAddDebt() =>
      _navigateTo(const AddDebtScreen());

  void _navigateToAddReceivable() =>
      _navigateTo(const AddReceivableScreen());
}

class _GojekServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _GojekServiceItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: iconColor.withValues(alpha: 0.12),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E2E2E),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
