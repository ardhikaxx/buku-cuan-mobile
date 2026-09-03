import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/constants/app_constants.dart';

class CategoryService {
  final CollectionReference _categoriesCollection =
      FirebaseService.firestore.collection('categories');

  Future<void> addCategory(CategoryModel category) async {
    await _categoriesCollection.doc(category.id).set(category.toFirestore());
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _categoriesCollection.doc(category.id).update(category.toFirestore());
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoriesCollection.doc(categoryId).delete();
  }

  Stream<List<CategoryModel>> getCategories(String workspaceId) {
    return _categoriesCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<CategoryModel>> getCategoriesByType(
      String workspaceId, String type) {
    return _categoriesCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .where('type', isEqualTo: type)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc))
            .toList());
  }

  Future<void> initializeDefaultCategories(String workspaceId) async {
    final existing = await _categoriesCollection
        .where('workspaceId', isEqualTo: workspaceId)
        .get();

    if (existing.docs.isNotEmpty) return;

    final batch = FirebaseService.firestore.batch();

    for (final name in AppConstants.defaultIncomeCategories) {
      final doc = _categoriesCollection.doc();
      batch.set(doc, {
        'workspaceId': workspaceId,
        'name': name,
        'type': 'income',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    for (final name in AppConstants.defaultExpenseCategories) {
      final doc = _categoriesCollection.doc();
      batch.set(doc, {
        'workspaceId': workspaceId,
        'name': name,
        'type': 'expense',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<bool> isCategoryUsed(String workspaceId, String categoryId) async {
    final query = await FirebaseService.firestore
        .collection('transactions')
        .where('workspaceId', isEqualTo: workspaceId)
        .where('categoryId', isEqualTo: categoryId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }
}
