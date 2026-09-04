import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/formatters.dart';

class CategoryModel {
  final String id;
  final String workspaceId;
  final String name;
  final String type; // 'income' or 'expense'
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CategoryModel(
      id: doc.id,
      workspaceId: (data['workspaceId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      type: (data['type'] ?? 'income').toString(),
      createdAt: SafeParser.parseDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workspaceId': workspaceId,
      'name': name,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
}
