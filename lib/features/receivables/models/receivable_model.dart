import 'package:cloud_firestore/cloud_firestore.dart';

enum ReceivableStatus { unpaid, partial, paid }

class ReceivableModel {
  final String id;
  final String workspaceId;
  final String name;
  final double amount;
  final double paidAmount;
  final double remainingAmount;
  final DateTime receivableDate;
  final DateTime dueDate;
  final ReceivableStatus status;
  final String? description;
  final DateTime createdAt;

  ReceivableModel({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.amount,
    this.paidAmount = 0,
    required this.remainingAmount,
    required this.receivableDate,
    required this.dueDate,
    this.status = ReceivableStatus.unpaid,
    this.description,
    required this.createdAt,
  });

  factory ReceivableModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReceivableModel(
      id: doc.id,
      workspaceId: data['workspaceId'] ?? '',
      name: data['name'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paidAmount: (data['paidAmount'] ?? 0).toDouble(),
      remainingAmount: (data['remainingAmount'] ?? 0).toDouble(),
      receivableDate: (data['receivableDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ReceivableStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ReceivableStatus.unpaid,
      ),
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workspaceId': workspaceId,
      'name': name,
      'amount': amount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'receivableDate': Timestamp.fromDate(receivableDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status.name,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status != ReceivableStatus.paid;

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;
}
