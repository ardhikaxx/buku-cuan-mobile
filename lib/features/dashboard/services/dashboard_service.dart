import '../../../core/services/firebase_service.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/services/transaction_service.dart';
import '../../debts/services/debt_service.dart';
import '../../receivables/services/receivable_service.dart';
import '../../capital/services/capital_service.dart';

class DashboardService {
  final TransactionService _transactionService = TransactionService();
  final DebtService _debtService = DebtService();
  final ReceivableService _receivableService = ReceivableService();
  final CapitalService _capitalService = CapitalService();

  Future<Map<String, double>> getSummary(String workspaceId) async {
    final totalIncome = await _transactionService.getTotalByType(workspaceId, 'income');
    final totalExpense = await _transactionService.getTotalByType(workspaceId, 'expense');
    final totalDebt = await _debtService.getTotalDebt(workspaceId);
    final totalReceivable = await _receivableService.getTotalReceivable(workspaceId);
    final totalCapital = await _capitalService.getTotalCapital(workspaceId);

    final balance = totalIncome - totalExpense + totalCapital;
    final netProfit = totalIncome - totalExpense;

    return {
      'balance': balance,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'netProfit': netProfit,
      'totalDebt': totalDebt,
      'totalReceivable': totalReceivable,
      'totalCapital': totalCapital,
    };
  }

  Future<List<Map<String, dynamic>>> getWeeklyData(String workspaceId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    final summary = await _transactionService.getSummaryByType(
      workspaceId,
      start,
      now,
    );

    return [
      {'label': 'Pemasukan', 'value': summary['income'] ?? 0},
      {'label': 'Pengeluaran', 'value': summary['expense'] ?? 0},
    ];
  }

  Future<List<Map<String, dynamic>>> getDailyCashFlow(
      String workspaceId, int days) async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> data = [];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));

      final summary = await _transactionService.getSummaryByType(
        workspaceId,
        start,
        end,
      );

      data.add({
        'date': start,
        'income': summary['income'] ?? 0,
        'expense': summary['expense'] ?? 0,
      });
    }

    return data;
  }

  Future<List<TransactionModel>> getRecentTransactions(
      String workspaceId, int limit) async {
    final query = await FirebaseService.firestore
        .collection('transactions')
        .where('workspaceId', isEqualTo: workspaceId)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();

    return query.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList();
  }
}
