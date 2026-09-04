import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/formatters.dart';

class TransactionModel {
  final String id;
  final String workspaceId;
  final String type; // 'income' or 'expense'
  final double amount;
  final String categoryId;
  final String categoryName;
  final DateTime date;
  final String description;
  final String paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.workspaceId,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    required this.description,
    required this.paymentMethod,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TransactionModel(
      id: doc.id,
      workspaceId: (data['workspaceId'] ?? '').toString(),
      type: (data['type'] ?? 'income').toString(),
      amount: SafeParser.parseDouble(data['amount']),
      categoryId: (data['categoryId'] ?? '').toString(),
      categoryName: (data['categoryName'] ?? '').toString(),
      date: SafeParser.parseDateTime(data['date']),
      description: (data['description'] ?? '').toString(),
      paymentMethod: (data['paymentMethod'] ?? 'Tunai').toString(),
      notes: data['notes']?.toString(),
      createdAt: SafeParser.parseDateTime(data['createdAt']),
      updatedAt: SafeParser.parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workspaceId': workspaceId,
      'type': type,
      'amount': amount,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'date': Timestamp.fromDate(date),
      'description': description,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
}
