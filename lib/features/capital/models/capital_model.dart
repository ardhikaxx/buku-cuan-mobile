import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/formatters.dart';

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
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CapitalModel(
      id: doc.id,
      workspaceId: (data['workspaceId'] ?? '').toString(),
      type: (data['type'] ?? 'initial').toString(),
      amount: SafeParser.parseDouble(data['amount']),
      date: SafeParser.parseDateTime(data['date']),
      description: data['description']?.toString(),
      createdAt: SafeParser.parseDateTime(data['createdAt']),
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
