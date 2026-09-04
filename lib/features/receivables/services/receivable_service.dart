import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/receivable_model.dart';
import '../../../core/services/firebase_service.dart';

class ReceivableService {
  static const _server = GetOptions(source: Source.server);
  final CollectionReference _receivablesCollection =
      FirebaseService.firestore.collection('receivables');

  Future<void> addReceivable(ReceivableModel receivable) async {
    await _receivablesCollection.doc(receivable.id).set(receivable.toFirestore());
  }

  Future<void> updateReceivable(ReceivableModel receivable) async {
    await _receivablesCollection.doc(receivable.id).update(receivable.toFirestore());
  }

  Future<void> deleteReceivable(String receivableId) async {
    await _receivablesCollection.doc(receivableId).delete();
  }

  Future<void> makePayment(String receivableId, double amount) async {
    final doc = await _receivablesCollection.doc(receivableId).get();
    final receivable = ReceivableModel.fromFirestore(doc);

    final newPaidAmount = receivable.paidAmount + amount;
    final newRemaining = receivable.amount - newPaidAmount;

    String newStatus;
    if (newRemaining <= 0) {
      newStatus = 'paid';
    } else if (newPaidAmount > 0) {
      newStatus = 'partial';
    } else {
      newStatus = 'unpaid';
    }

    await _receivablesCollection.doc(receivableId).update({
      'paidAmount': newPaidAmount,
      'remainingAmount': newRemaining < 0 ? 0 : newRemaining,
      'status': newStatus,
    });
  }

  Stream<List<ReceivableModel>> getReceivables(String workspaceId) {
    return _receivablesCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .snapshots()
        .map((snapshot) {
      final receivables = snapshot.docs
          .map((doc) => ReceivableModel.fromFirestore(doc))
          .toList();
      receivables.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return receivables;
    });
  }

  Stream<List<ReceivableModel>> getActiveReceivables(String workspaceId) {
    return _receivablesCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .snapshots()
        .map((snapshot) {
      final receivables = snapshot.docs
          .map((doc) => ReceivableModel.fromFirestore(doc))
          .where((r) => r.status != ReceivableStatus.paid)
          .toList();
      receivables.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return receivables;
    });
  }

  Future<double> getTotalReceivable(String workspaceId) async {
    try {
      final query = await _receivablesCollection
          .where('workspaceId', isEqualTo: workspaceId)
          .get(_server);

      double total = 0;
      for (final doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['status'] != 'paid') {
          total += (data['remainingAmount'] ?? 0).toDouble();
        }
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<List<ReceivableModel>> getOverdueReceivables(String workspaceId) async {
    try {
      final query = await _receivablesCollection
          .where('workspaceId', isEqualTo: workspaceId)
          .get(_server);

      final now = DateTime.now();
      return query.docs
          .map((doc) => ReceivableModel.fromFirestore(doc))
          .where((r) => r.status != ReceivableStatus.paid && r.dueDate.isBefore(now))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
