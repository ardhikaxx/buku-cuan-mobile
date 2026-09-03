import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_model.dart';
import '../../../core/services/firebase_service.dart';

class ReminderService {
  final CollectionReference _remindersCollection =
      FirebaseService.firestore.collection('reminders');

  Future<void> addReminder(ReminderModel reminder) async {
    await _remindersCollection.doc(reminder.id).set(reminder.toFirestore());
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    await _remindersCollection.doc(reminder.id).update(reminder.toFirestore());
  }

  Future<void> deleteReminder(String reminderId) async {
    await _remindersCollection.doc(reminderId).delete();
  }

  Future<void> markCompleted(String reminderId) async {
    await _remindersCollection.doc(reminderId).update({
      'isCompleted': true,
    });
  }

  Stream<List<ReminderModel>> getReminders(String workspaceId) {
    return _remindersCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReminderModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<ReminderModel>> getActiveReminders(String workspaceId) {
    return _remindersCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .where('isCompleted', isEqualTo: false)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReminderModel.fromFirestore(doc))
            .toList());
  }

  Future<List<ReminderModel>> getUpcomingReminders(
      String workspaceId, int days) async {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));

    final query = await _remindersCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .where('isCompleted', isEqualTo: false)
        .get();

    return query.docs
        .map((doc) => ReminderModel.fromFirestore(doc))
        .where((r) =>
            r.dueDate.isAfter(now) && r.dueDate.isBefore(futureDate))
        .toList();
  }
}
