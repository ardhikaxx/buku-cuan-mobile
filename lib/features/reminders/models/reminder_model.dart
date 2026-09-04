import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/formatters.dart';

class ReminderModel {
  final String id;
  final String workspaceId;
  final String type; // 'debt' or 'receivable'
  final String? referenceId;
  final String title;
  final double amount;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime createdAt;

  ReminderModel({
    required this.id,
    required this.workspaceId,
    required this.type,
    this.referenceId,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory ReminderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReminderModel(
      id: doc.id,
      workspaceId: (data['workspaceId'] ?? '').toString(),
      type: (data['type'] ?? 'debt').toString(),
      referenceId: data['referenceId']?.toString(),
      title: (data['title'] ?? '').toString(),
      amount: SafeParser.parseDouble(data['amount']),
      dueDate: SafeParser.parseDateTime(data['dueDate']),
      isCompleted: data['isCompleted'] == true,
      createdAt: SafeParser.parseDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workspaceId': workspaceId,
      'type': type,
      'referenceId': referenceId,
      'title': title,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isDebt => type == 'debt';
  bool get isReceivable => type == 'receivable';

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;
}
