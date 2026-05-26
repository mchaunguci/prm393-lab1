import 'package:shopee_app/models/product.dart';

class ShopAnalyticsItem {
  final int shopId;
  final String shopName;
  final String location;
  final String locationGroup;
  final bool isOfficial;
  final int productCount;
  final int totalSold;
  final int monthlySold;
  final double averageRating;
  final int totalRatingCount;
  final double averagePrice;
  final double totalRevenueEstimate;
  final double averageDiscount;
  final List<Product> products;

  const ShopAnalyticsItem({
    required this.shopId,
    required this.shopName,
    required this.location,
    required this.locationGroup,
    required this.isOfficial,
    required this.productCount,
    required this.totalSold,
    required this.monthlySold,
    required this.averageRating,
    required this.totalRatingCount,
    required this.averagePrice,
    required this.totalRevenueEstimate,
    required this.averageDiscount,
    required this.products,
  });
}
