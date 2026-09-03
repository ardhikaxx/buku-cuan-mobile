import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import '../../../core/services/firebase_service.dart';

class TransactionService {
  final CollectionReference _transactionsCollection =
      FirebaseService.firestore.collection('transactions');

  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactionsCollection.doc(transaction.id).set(transaction.toFirestore());
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _transactionsCollection.doc(transaction.id).update({
      ...transaction.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _transactionsCollection.doc(transactionId).delete();
  }

  Stream<List<TransactionModel>> getTransactions(String workspaceId) {
    return _transactionsCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<TransactionModel>> getTransactionsByType(
      String workspaceId, String type) {
    return _transactionsCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .where('type', isEqualTo: type)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<TransactionModel>> getTransactionsByDateRange(
      String workspaceId, DateTime start, DateTime end) {
    return _transactionsCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  Future<double> getTotalByType(String workspaceId, String type) async {
    final query = await _transactionsCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .where('type', isEqualTo: type)
        .get();

    double total = 0;
    for (final doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['amount'] ?? 0).toDouble();
    }
    return total;
  }

  Future<Map<String, double>> getSummaryByType(
      String workspaceId, DateTime start, DateTime end) async {
    final query = await _transactionsCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    double income = 0;
    double expense = 0;

    for (final doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] ?? 0).toDouble();
      if (data['type'] == 'income') {
        income += amount;
      } else {
        expense += amount;
      }
    }

    return {'income': income, 'expense': expense};
  }

  Future<List<Map<String, dynamic>>> getCategoryBreakdown(
      String workspaceId, String type, DateTime start, DateTime end) async {
    final query = await _transactionsCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .where('type', isEqualTo: type)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final Map<String, double> breakdown = {};
    for (final doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final categoryName = data['categoryName'] ?? 'Lainnya';
      final amount = (data['amount'] ?? 0).toDouble();
      breakdown[categoryName] = (breakdown[categoryName] ?? 0) + amount;
    }

    return breakdown.entries
        .map((e) => {'category': e.key, 'amount': e.value})
        .toList()
      ..sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
  }
}
