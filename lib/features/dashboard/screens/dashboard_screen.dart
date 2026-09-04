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
import '../../transactions/widgets/transaction_list_tile.dart';
import '../../debts/screens/add_debt_screen.dart';
import '../../receivables/screens/add_receivable_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<AppProvider>();
    if (provider.workspaceId == null) return;

    try {
      final summary = await _dashboardService.getSummary(provider.workspaceId!);
      final weeklyData = await _dashboardService.getDailyCashFlow(provider.workspaceId!, 7);
      final recentTransactions =
          await _dashboardService.getRecentTransactions(provider.workspaceId!, 5);

      setState(() {
        _summary = summary;
        _weeklyData = weeklyData;
        _recentTransactions = recentTransactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 16),
          _buildBalanceCard(),
          const SizedBox(height: 12),
          _buildSummaryRow(),
          const SizedBox(height: 16),
          _buildQuickActions(),
          const SizedBox(height: 16),
          _buildCashFlowChart(),
          const SizedBox(height: 16),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final provider = context.watch<AppProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selamat datang di Buku Cuan',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          provider.userName ?? 'Usaha Saya',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    final balance = _summary['balance'] ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatRupiah(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Uang Masuk',
            amount: _summary['totalIncome'] ?? 0,
            color: AppColors.income,
            icon: Icons.arrow_downward,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'Uang Keluar',
            amount: _summary['totalExpense'] ?? 0,
            color: AppColors.expense,
            icon: Icons.arrow_upward,
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
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickAction(
              icon: Icons.add_circle,
              label: 'Uang Masuk',
              color: AppColors.income,
              onTap: () => _navigateToAddTransaction('income'),
            ),
            const SizedBox(width: 8),
            _QuickAction(
              icon: Icons.remove_circle,
              label: 'Uang Keluar',
              color: AppColors.expense,
              onTap: () => _navigateToAddTransaction('expense'),
            ),
            const SizedBox(width: 8),
            _QuickAction(
              icon: Icons.money_off,
              label: 'Hutang',
              color: AppColors.debt,
              onTap: () => _navigateToAddDebt(),
            ),
            const SizedBox(width: 8),
            _QuickAction(
              icon: Icons.request_page,
              label: 'Piutang',
              color: AppColors.receivable,
              onTap: () => _navigateToAddReceivable(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCashFlowChart() {
    if (_weeklyData.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Arus Kas 7 Hari Terakhir',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxY(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          CurrencyFormatter.formatRupiahShort(rod.toY),
                          const TextStyle(color: Colors.white, fontSize: 11),
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
                            return Text(
                              DateFormatter.formatDayMonth(date),
                              style: const TextStyle(fontSize: 10),
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
                    final income = entry.value['income'] as double;
                    final expense = entry.value['expense'] as double;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: income,
                          color: AppColors.income,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: expense,
                          color: AppColors.expense,
                          width: 12,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaksi Terbaru',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (_recentTransactions.isEmpty)
              const Center(
                child: EmptyState(
                  icon: Icons.receipt_long,
                  title: 'Belum ada transaksi',
                  subtitle: 'Mulai catat pemasukan atau pengeluaran usaha Anda.',
                ),
              )
            else
              ...(_recentTransactions.map(
                (t) => TransactionListTile(transaction: t),
              )),
          ],
        ),
      ),
    );
  }

  void _navigateToAddTransaction(String type) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialType: type),
      ),
    );
    _loadData();
  }

  void _navigateToAddDebt() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddDebtScreen()),
    );
    _loadData();
  }

  void _navigateToAddReceivable() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddReceivableScreen()),
    );
    _loadData();
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.formatRupiahShort(amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
