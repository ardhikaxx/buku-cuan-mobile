import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/formatters.dart';

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
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final amount = SafeParser.parseDouble(data['amount']);
    final paidAmount = SafeParser.parseDouble(data['paidAmount']);
    final remainingAmount = data.containsKey('remainingAmount')
        ? SafeParser.parseDouble(data['remainingAmount'])
        : (amount - paidAmount);

    return DebtModel(
      id: doc.id,
      workspaceId: (data['workspaceId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      amount: amount,
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
      debtDate: SafeParser.parseDateTime(data['debtDate']),
      dueDate: SafeParser.parseDateTime(data['dueDate']),
      status: DebtStatus.values.firstWhere(
        (e) => e.name == data['status']?.toString(),
        orElse: () => DebtStatus.unpaid,
      ),
      description: data['description']?.toString(),
      createdAt: SafeParser.parseDateTime(data['createdAt']),
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
