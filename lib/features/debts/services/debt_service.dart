import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/debt_model.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/formatters.dart';

class DebtService {
  final CollectionReference _debtsCollection =
      FirebaseService.firestore.collection('debts');

  Future<void> addDebt(DebtModel debt) async {
    await _debtsCollection.doc(debt.id).set(debt.toFirestore());
  }

  Future<void> updateDebt(DebtModel debt) async {
    await _debtsCollection.doc(debt.id).update(debt.toFirestore());
  }

  Future<void> deleteDebt(String debtId) async {
    await _debtsCollection.doc(debtId).delete();
  }

  Future<void> makePayment(String debtId, double amount) async {
    final doc = await _debtsCollection.doc(debtId).get();
    final debt = DebtModel.fromFirestore(doc);

    final newPaidAmount = debt.paidAmount + amount;
    final newRemaining = debt.amount - newPaidAmount;

    String newStatus;
    if (newRemaining <= 0) {
      newStatus = 'lunas';
    } else if (newPaidAmount > 0) {
      newStatus = 'sebagian';
    } else {
      newStatus = 'belum_lunas';
    }

    await _debtsCollection.doc(debtId).update({
      'paidAmount': newPaidAmount,
      'remainingAmount': newRemaining < 0 ? 0 : newRemaining,
      'status': newStatus,
    });
  }

  Stream<List<DebtModel>> getDebts(String workspaceId) {
    return _debtsCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .snapshots()
        .map((snapshot) {
      final debts = snapshot.docs
          .map((doc) => DebtModel.fromFirestore(doc))
          .toList();
      debts.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return debts;
    });
  }

  Stream<List<DebtModel>> getActiveDebts(String workspaceId) {
    return _debtsCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .snapshots()
        .map((snapshot) {
      final debts = snapshot.docs
          .map((doc) => DebtModel.fromFirestore(doc))
          .where((d) => d.status != DebtStatus.paid)
          .toList();
      debts.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return debts;
    });
  }

  Future<double> getTotalDebt(String workspaceId) async {
    try {
      final query = await _debtsCollection
          .where('workspaceId', isEqualTo: workspaceId)
          .get();

      double total = 0;
      for (final doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final status = data['status']?.toString();
        if (status != 'lunas' && status != 'paid') {
          final remaining = data.containsKey('remainingAmount')
              ? SafeParser.parseDouble(data['remainingAmount'])
              : (SafeParser.parseDouble(data['amount']) - SafeParser.parseDouble(data['paidAmount']));
          total += remaining;
        }
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<List<DebtModel>> getOverdueDebts(String workspaceId) async {
    try {
      final query = await _debtsCollection
          .where('workspaceId', isEqualTo: workspaceId)
          .get();

      final now = DateTime.now();
      return query.docs
          .map((doc) => DebtModel.fromFirestore(doc))
          .where((debt) => debt.status != DebtStatus.paid && debt.dueDate.isBefore(now))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<DebtModel>> getUpcomingDebts(String workspaceId, int days) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: days));

      final query = await _debtsCollection
          .where('workspaceId', isEqualTo: workspaceId)
          .get();

      return query.docs
          .map((doc) => DebtModel.fromFirestore(doc))
          .where((debt) =>
              debt.status != DebtStatus.paid &&
              debt.dueDate.isAfter(now) &&
              debt.dueDate.isBefore(futureDate))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
