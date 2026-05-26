import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final int categoryId;
  final String? categoryName;

  Category({
    required this.categoryId,
    this.categoryName,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Category(
      categoryId: (d['category_id'] as num?)?.toInt() ?? 0,
      categoryName: d['category_name'],
    );
  }
}
