import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/capital_model.dart';
import '../../../core/services/firebase_service.dart';

class CapitalService {
  final CollectionReference _capitalCollection =
      FirebaseService.firestore.collection('capital');

  Future<void> addCapital(CapitalModel capital) async {
    await _capitalCollection.doc(capital.id).set(capital.toFirestore());
  }

  Future<void> updateCapital(CapitalModel capital) async {
    await _capitalCollection.doc(capital.id).update(capital.toFirestore());
  }

  Future<void> deleteCapital(String capitalId) async {
    await _capitalCollection.doc(capitalId).delete();
  }

  Stream<List<CapitalModel>> getCapital(String workspaceId) {
    return _capitalCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CapitalModel.fromFirestore(doc))
            .toList());
  }

  Future<double> getTotalCapital(String workspaceId) async {
    try {
      final query = await _capitalCollection
          .where('workspaceId', isEqualTo: workspaceId)
          .get();

      double total = 0;
      for (final doc in query.docs) {
        final capital = CapitalModel.fromFirestore(doc);
        total += capital.signedAmount;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }
}
