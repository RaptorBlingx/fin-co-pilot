import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing user-created custom categories in Firestore.
class CustomCategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  /// Fetch all custom categories for the current user.
  Future<List<CustomCategory>> getCustomCategories() async {
    final uid = _userId;
    if (uid == null) return [];

    try {
      final snapshot = await _firestore
          .collection('user_categories')
          .where('user_id', isEqualTo: uid)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CustomCategory.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Fallback without orderBy if composite index is missing
      try {
        final snapshot = await _firestore
            .collection('user_categories')
            .where('user_id', isEqualTo: uid)
            .get();

        final categories = snapshot.docs
            .map((doc) => CustomCategory.fromFirestore(doc))
            .toList();
        categories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return categories;
      } catch (e2) {
        return [];
      }
    }
  }

  /// Add a new custom category.
  Future<CustomCategory?> addCategory({
    required String name,
    required String iconName,
    required int colorValue,
  }) async {
    final uid = _userId;
    if (uid == null) return null;

    final doc = await _firestore.collection('user_categories').add({
      'user_id': uid,
      'name': name,
      'icon_name': iconName,
      'color_value': colorValue,
      'created_at': FieldValue.serverTimestamp(),
    });

    return CustomCategory(
      id: doc.id,
      userId: uid,
      name: name,
      iconName: iconName,
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );
  }

  /// Delete a custom category.
  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection('user_categories').doc(categoryId).delete();
  }

  /// Update a custom category.
  Future<void> updateCategory({
    required String categoryId,
    required String name,
    required String iconName,
    required int colorValue,
  }) async {
    await _firestore.collection('user_categories').doc(categoryId).update({
      'name': name,
      'icon_name': iconName,
      'color_value': colorValue,
    });
  }
}

class CustomCategory {
  final String id;
  final String userId;
  final String name;
  final String iconName;
  final int colorValue;
  final DateTime createdAt;

  CustomCategory({
    required this.id,
    required this.userId,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.createdAt,
  });

  factory CustomCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomCategory(
      id: doc.id,
      userId: data['user_id'] ?? '',
      name: data['name'] ?? '',
      iconName: data['icon_name'] ?? 'tag',
      colorValue: data['color_value'] ?? 0xFF6366F1,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
