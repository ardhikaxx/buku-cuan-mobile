import 'package:cloud_firestore/cloud_firestore.dart';

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
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      workspaceId: data['workspaceId'] ?? '',
      type: data['type'] ?? 'income',
      amount: (data['amount'] ?? 0).toDouble(),
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] ?? '',
      paymentMethod: data['paymentMethod'] ?? 'Tunai',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
