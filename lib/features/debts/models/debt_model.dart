import 'package:cloud_firestore/cloud_firestore.dart';

enum DebtStatus { unpaid, partial, paid }

class DebtModel {
  final String id;
  final String workspaceId;
  final String name;
  final double amount;
  final double paidAmount;
  final double remainingAmount;
  final DateTime debtDate;
  final DateTime dueDate;
  final DebtStatus status;
  final String? description;
  final DateTime createdAt;

  DebtModel({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.amount,
    this.paidAmount = 0,
    required this.remainingAmount,
    required this.debtDate,
    required this.dueDate,
    this.status = DebtStatus.unpaid,
    this.description,
    required this.createdAt,
  });

  factory DebtModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DebtModel(
      id: doc.id,
      workspaceId: data['workspaceId'] ?? '',
      name: data['name'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paidAmount: (data['paidAmount'] ?? 0).toDouble(),
      remainingAmount: (data['remainingAmount'] ?? 0).toDouble(),
      debtDate: (data['debtDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: DebtStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => DebtStatus.unpaid,
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
      'debtDate': Timestamp.fromDate(debtDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status.name,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status != DebtStatus.paid;

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;
}
