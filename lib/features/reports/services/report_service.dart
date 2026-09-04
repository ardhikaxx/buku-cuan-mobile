import '../../transactions/services/transaction_service.dart';
import '../../debts/services/debt_service.dart';
import '../../receivables/services/receivable_service.dart';
import '../../capital/services/capital_service.dart';

class ReportService {
  final TransactionService _transactionService = TransactionService();
  final DebtService _debtService = DebtService();
  final ReceivableService _receivableService = ReceivableService();
  final CapitalService _capitalService = CapitalService();

  Future<Map<String, dynamic>> getReportData({
    required String workspaceId,
    required DateTime start,
    required DateTime end,
  }) async {
    final summary =
        await _transactionService.getSummaryByType(workspaceId, start, end);
    final incomeByCat = await _transactionService.getCategoryBreakdown(
        workspaceId, 'income', start, end);
    final expenseByCat = await _transactionService.getCategoryBreakdown(
        workspaceId, 'expense', start, end);
    final totalDebt = await _debtService.getTotalDebt(workspaceId);
    final totalReceivable =
        await _receivableService.getTotalReceivable(workspaceId);
    final totalCapital = await _capitalService.getTotalCapital(workspaceId);

    final double totalIncome = summary['income'] ?? 0.0;
    final double totalExpense = summary['expense'] ?? 0.0;
    final double netProfit = totalIncome - totalExpense;

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'netProfit': netProfit,
      'totalDebt': totalDebt,
      'totalReceivable': totalReceivable,
      'totalCapital': totalCapital,
      'incomeByCategory': incomeByCat,
      'expenseByCategory': expenseByCat,
    };
  }
}
