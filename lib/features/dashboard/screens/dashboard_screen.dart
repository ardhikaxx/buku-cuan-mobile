import 'package:flutter/material.dart';
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
import '../../debts/screens/debt_list_screen.dart';
import '../../receivables/screens/add_receivable_screen.dart';
import '../../receivables/screens/receivable_list_screen.dart';
import '../../capital/screens/capital_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  Map<String, double> _summary = {};
  List<Map<String, dynamic>> _weeklyData = [];
  List<TransactionModel> _recentTransactions = [];
  bool _isLoading = true;
  bool _isBalanceVisible = true;

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
      final weeklyData = await _dashboardService.getDailyCashFlow(provider.workspaceId!, 7);
      final recentTransactions =
          await _dashboardService.getRecentTransactions(provider.workspaceId!, 5);

      if (mounted) {
        setState(() {
          _summary = summary;
          _weeklyData = weeklyData;
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
              _buildMetricGrid(),
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
            color: Colors.white,
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
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary, size: 20),
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
                          Icon(Icons.account_balance_wallet_rounded, size: 14, color: Colors.white),
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
                          _isBalanceVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
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
                              child: const Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 16),
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
                              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 16),
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

  Widget _buildMetricGrid() {
    final netProfit = _summary['netProfit'] ?? 0;
    final totalDebt = _summary['totalDebt'] ?? 0;
    final totalReceivable = _summary['totalReceivable'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Laba Bersih',
            amount: netProfit,
            icon: Icons.trending_up_rounded,
            color: netProfit >= 0 ? AppColors.income : AppColors.expense,
            isProfit: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            title: 'Hutang',
            amount: totalDebt,
            icon: Icons.money_off_csred_rounded,
            color: AppColors.debt,
            onTap: () => _navigateTo(const DebtListScreen()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            title: 'Piutang',
            amount: totalReceivable,
            icon: Icons.request_quote_rounded,
            color: AppColors.receivable,
            onTap: () => _navigateTo(const ReceivableListScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aksi Cepat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _ActionButton(
              icon: Icons.arrow_downward_rounded,
              label: 'Uang Masuk',
              color: AppColors.income,
              onTap: () => _navigateToAddTransaction('income'),
            ),
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.arrow_upward_rounded,
              label: 'Uang Keluar',
              color: AppColors.expense,
              onTap: () => _navigateToAddTransaction('expense'),
            ),
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.money_off_csred_rounded,
              label: 'Hutang',
              color: AppColors.debt,
              onTap: () => _navigateToAddDebt(),
            ),
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.request_quote_rounded,
              label: 'Piutang',
              color: AppColors.receivable,
              onTap: () => _navigateToAddReceivable(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _navigateTo(const CapitalScreen()),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_rounded, size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kelola Modal Usaha',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Catat penambahan modal & penarikan (Prive)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCashFlowChart() {
    final bool hasData = _weeklyData.isNotEmpty &&
        _weeklyData.any((d) => ((d['income'] as double?) ?? 0) > 0 || ((d['expense'] as double?) ?? 0) > 0);

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
                  Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Arus Kas 7 Hari Terakhir',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (hasData)
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
          if (!hasData)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: EmptyState(
                  icon: Icons.bar_chart_rounded,
                  title: 'Belum ada aktivitas arus kas',
                  subtitle: 'Grafik transaksi 7 hari terakhir akan muncul setelah Anda mencatat pemasukan atau pengeluaran.',
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
                        final isIncome = rodIndex == 0;
                        final label = isIncome ? 'Masuk: ' : 'Keluar: ';
                        return BarTooltipItem(
                          '$label${CurrencyFormatter.formatRupiah(rod.toY)}',
                          const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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
                          if (index >= 0 && index < _weeklyData.length) {
                            final date = _weeklyData[index]['date'] as DateTime;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                DateFormatter.formatDayMonth(date),
                                style: const TextStyle(
                                  fontSize: 10,
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
                  barGroups: _weeklyData.asMap().entries.map((entry) {
                    final income = (entry.value['income'] as double?) ?? 0;
                    final expense = (entry.value['expense'] as double?) ?? 0;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: income,
                          color: AppColors.income,
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                        ),
                        BarChartRodData(
                          toY: expense,
                          color: AppColors.expense,
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
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

  double _getMaxY() {
    double max = 0;
    for (final data in _weeklyData) {
      final income = data['income'] as double;
      final expense = data['expense'] as double;
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
                  Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
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
                        Icons.chevron_right_rounded,
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
                  icon: Icons.receipt_long_rounded,
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

class _MetricCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isProfit;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.isProfit = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 15, color: color),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  CurrencyFormatter.formatRupiahShort(amount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isProfit
                        ? (amount >= 0 ? AppColors.income : AppColors.expense)
                        : color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            decoration: BoxDecoration(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
