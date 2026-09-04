import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
        .snapshots()
        .map((snapshot) {
      final txns = snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
      txns.sort((a, b) => b.date.compareTo(a.date));
      return txns;
    });
  }

  Stream<List<TransactionModel>> getTransactionsByType(
      String workspaceId, String type) {
    return _transactionsCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snapshot) {
      final txns = snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
      txns.sort((a, b) => b.date.compareTo(a.date));
      return txns;
    });
  }

  Stream<List<TransactionModel>> getTransactionsByDateRange(
      String workspaceId, DateTime start, DateTime end) {
    return _transactionsCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .snapshots()
        .map((snapshot) {
      final txns = snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
          .toList();
      txns.sort((a, b) => b.date.compareTo(a.date));
      return txns;
    });
  }

  Future<double> getTotalByType(String workspaceId, String type, {dynamic source}) async {
    try {
      final options = source != null ? GetOptions(source: source) : null;
      final query = await _transactionsCollection
          .where('workspaceId', isEqualTo: workspaceId)
          .get(options);

      double total = 0;
      for (final doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['type'] == type) {
          total += (data['amount'] ?? 0).toDouble();
        }
      }
      return total;
    } catch (e) {
      debugPrint('Error getTotalByType($type): $e');
      return 0;
    }
  }

  Future<Map<String, double>> getSummaryByType(
      String workspaceId, DateTime start, DateTime end) async {
    try {
      final query = await _transactionsCollection
          .where('workspaceId', isEqualTo: workspaceId)
          .get();

      double income = 0;
      double expense = 0;

      for (final doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final ts = data['date'];
        DateTime? date;
        if (ts is Timestamp) {
          date = ts.toDate();
        } else if (ts is String) {
          date = DateTime.tryParse(ts);
        }

        if (date != null && (date.isBefore(start) || date.isAfter(end))) {
          continue;
        }

        final amount = (data['amount'] ?? 0).toDouble();
        if (data['type'] == 'income') {
          income += amount;
        } else if (data['type'] == 'expense') {
          expense += amount;
        }
      }

      return {'income': income, 'expense': expense};
    } catch (e) {
      return {'income': 0, 'expense': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getCategoryBreakdown(
      String workspaceId, String type, DateTime start, DateTime end) async {
    try {
      final query = await _transactionsCollection
          .where('workspaceId', isEqualTo: workspaceId)
          .get();

      final Map<String, double> breakdown = {};
      for (final doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['type'] != type) continue;

        final ts = data['date'];
        DateTime? date;
        if (ts is Timestamp) {
          date = ts.toDate();
        } else if (ts is String) {
          date = DateTime.tryParse(ts);
        }

        if (date != null && (date.isBefore(start) || date.isAfter(end))) {
          continue;
        }

        final categoryName = data['categoryName'] ?? 'Lainnya';
        final amount = (data['amount'] ?? 0).toDouble();
        breakdown[categoryName] = (breakdown[categoryName] ?? 0) + amount;
      }

      return breakdown.entries
          .map((e) => {'category': e.key, 'amount': e.value})
          .toList()
        ..sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    } catch (e) {
      return [];
    }
  }
}
