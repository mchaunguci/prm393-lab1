import 'package:cloud_firestore/cloud_firestore.dart';

class Shop {
  final int shopId;
  final String shopName;
  final String? shopLocation;
  final bool isOfficial;

  Shop({
    required this.shopId,
    required this.shopName,
    this.shopLocation,
    this.isOfficial = false,
  });

  factory Shop.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Shop(
      shopId: (d['shop_id'] as num?)?.toInt() ?? 0,
      shopName: d['shop_name'] ?? '',
      shopLocation: d['shop_location'],
      isOfficial: d['is_official'] ?? false,
    );
  }
}
