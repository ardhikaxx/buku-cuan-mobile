import 'package:cloud_firestore/cloud_firestore.dart';

class CapitalModel {
  final String id;
  final String workspaceId;
  final String type; // 'initial', 'additional', 'withdrawal'
  final double amount;
  final DateTime date;
  final String? description;
  final DateTime createdAt;

  CapitalModel({
    required this.id,
    required this.workspaceId,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
    required this.createdAt,
  });

  factory CapitalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CapitalModel(
      id: doc.id,
      workspaceId: data['workspaceId'] ?? '',
      type: data['type'] ?? 'initial',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workspaceId': workspaceId,
      'type': type,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isInitial => type == 'initial';
  bool get isAdditional => type == 'additional';
  bool get isWithdrawal => type == 'withdrawal';

  double get signedAmount {
    if (isWithdrawal) return -amount;
    return amount;
  }
}
