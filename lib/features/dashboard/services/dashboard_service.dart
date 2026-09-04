import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/formatters.dart';
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

  Future<List<Map<String, dynamic>>> getCashFlowData(
      String workspaceId, String filter) async {
    if (filter == 'monthly') {
      return getMonthlyCashFlow(workspaceId, DateTime.now().year);
    } else if (filter == 'yearly') {
      return getYearlyCashFlow(workspaceId, 5);
    } else {
      return getDailyCashFlow(workspaceId, 7);
    }
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
        'label': DateFormatter.formatDayMonth(start),
        'date': start,
        'income': summary['income'] ?? 0.0,
        'expense': summary['expense'] ?? 0.0,
      });
    }

    return data;
  }

  Future<List<Map<String, dynamic>>> getMonthlyCashFlow(
      String workspaceId, int year) async {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    final query = await FirebaseService.firestore
        .collection('transactions')
        .where('workspaceId', isEqualTo: workspaceId)
        .get();

    final List<Map<String, dynamic>> data = List.generate(12, (index) {
      return {
        'label': monthNames[index],
        'date': DateTime(year, index + 1, 1),
        'income': 0.0,
        'expense': 0.0,
      };
    });

    for (final doc in query.docs) {
      final d = doc.data();
      final ts = d['date'];
      DateTime? date;
      if (ts is Timestamp) {
        date = ts.toDate();
      } else if (ts is String) {
        date = DateTime.tryParse(ts);
      }

      if (date != null && date.year == year) {
        final monthIndex = date.month - 1;
        if (monthIndex >= 0 && monthIndex < 12) {
          final amount = ((d['amount'] ?? 0) as num).toDouble();
          if (d['type'] == 'income') {
            data[monthIndex]['income'] = (data[monthIndex]['income'] as double) + amount;
          } else if (d['type'] == 'expense') {
            data[monthIndex]['expense'] = (data[monthIndex]['expense'] as double) + amount;
          }
        }
      }
    }

    return data;
  }

  Future<List<Map<String, dynamic>>> getYearlyCashFlow(
      String workspaceId, int yearsCount) async {
    final currentYear = DateTime.now().year;
    final startYear = currentYear - yearsCount + 1;

    final query = await FirebaseService.firestore
        .collection('transactions')
        .where('workspaceId', isEqualTo: workspaceId)
        .get();

    final Map<int, Map<String, double>> yearlyTotals = {};
    for (int y = startYear; y <= currentYear; y++) {
      yearlyTotals[y] = {'income': 0.0, 'expense': 0.0};
    }

    for (final doc in query.docs) {
      final d = doc.data();
      final ts = d['date'];
      DateTime? date;
      if (ts is Timestamp) {
        date = ts.toDate();
      } else if (ts is String) {
        date = DateTime.tryParse(ts);
      }

      if (date != null && yearlyTotals.containsKey(date.year)) {
        final amount = ((d['amount'] ?? 0) as num).toDouble();
        if (d['type'] == 'income') {
          yearlyTotals[date.year]!['income'] =
              (yearlyTotals[date.year]!['income'] ?? 0.0) + amount;
        } else if (d['type'] == 'expense') {
          yearlyTotals[date.year]!['expense'] =
              (yearlyTotals[date.year]!['expense'] ?? 0.0) + amount;
        }
      }
    }

    return yearlyTotals.entries.map((e) {
      return {
        'label': '${e.key}',
        'date': DateTime(e.key, 1, 1),
        'income': e.value['income'] ?? 0.0,
        'expense': e.value['expense'] ?? 0.0,
      };
    }).toList();
  }

  Future<List<TransactionModel>> getRecentTransactions(
      String workspaceId, int limit) async {
    try {
      final query = await FirebaseService.firestore
          .collection('transactions')
          .where('workspaceId', isEqualTo: workspaceId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      final query = await FirebaseService.firestore
          .collection('transactions')
          .where('workspaceId', isEqualTo: workspaceId)
          .get();

      final docs = query.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
      docs.sort((a, b) => b.date.compareTo(a.date));
      return docs.take(limit).toList();
    }
  }
}
