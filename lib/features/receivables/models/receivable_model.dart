import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/formatters.dart';

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
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final amount = SafeParser.parseDouble(data['amount']);
    final paidAmount = SafeParser.parseDouble(data['paidAmount']);
    final remainingAmount = data.containsKey('remainingAmount')
        ? SafeParser.parseDouble(data['remainingAmount'])
        : (amount - paidAmount);

    return ReceivableModel(
      id: doc.id,
      workspaceId: (data['workspaceId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      amount: amount,
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
      receivableDate: SafeParser.parseDateTime(data['receivableDate']),
      dueDate: SafeParser.parseDateTime(data['dueDate']),
      status: ReceivableStatus.values.firstWhere(
        (e) => e.name == data['status']?.toString(),
        orElse: () => ReceivableStatus.unpaid,
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
