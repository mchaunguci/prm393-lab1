import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final int productId;
  final int shopId;
  final int? categoryId;
  final String name;
  final String url;
  final String? thumbnailUrl;
  final List<String> images;
  final List<String> variationsImages;

  final double price;
  final double? priceMax;
  final double? priceMin;
  final double? priceBeforeDiscount;
  final double? originalPrice;
  final int discount;
  final String? discountText;

  final double rating;
  final int ratingCount;
  final int star1Count;
  final int star2Count;
  final int star3Count;
  final int star4Count;
  final int star5Count;

  final int soldCount;
  final String? soldCountText;
  final int monthlySoldCount;
  final int likedCount;

  final String? colors;
  final String? sizes;
  final String? variations;

  final bool isAdult;
  final bool isServiceByShopee;
  final bool isShopeeChoice;
  final bool isOnFlashSale;
  final bool isOfficialShop;
  final bool isPreferredPlusSeller;
  final bool isLowestPrice;
  final bool? isLiveStreamingPrice;
  final bool isMart;
  final bool canUseCod;
  final bool canUseWholesale;
  final bool hasLowestPriceGuarantee;
  final bool showFreeShipping;

  final DateTime? shopeeCreatedAt;
  final String? sourceUrl;
  final DateTime? extractedAt;

  Product({
    required this.productId,
    required this.shopId,
    this.categoryId,
    required this.name,
    required this.url,
    this.thumbnailUrl,
    this.images = const [],
    this.variationsImages = const [],
    required this.price,
    this.priceMax,
    this.priceMin,
    this.priceBeforeDiscount,
    this.originalPrice,
    this.discount = 0,
    this.discountText,
    this.rating = 0,
    this.ratingCount = 0,
    this.star1Count = 0,
    this.star2Count = 0,
    this.star3Count = 0,
    this.star4Count = 0,
    this.star5Count = 0,
    this.soldCount = 0,
    this.soldCountText,
    this.monthlySoldCount = 0,
    this.likedCount = 0,
    this.colors,
    this.sizes,
    this.variations,
    this.isAdult = false,
    this.isServiceByShopee = false,
    this.isShopeeChoice = false,
    this.isOnFlashSale = false,
    this.isOfficialShop = false,
    this.isPreferredPlusSeller = false,
    this.isLowestPrice = false,
    this.isLiveStreamingPrice,
    this.isMart = false,
    this.canUseCod = false,
    this.canUseWholesale = false,
    this.hasLowestPriceGuarantee = false,
    this.showFreeShipping = false,
    this.shopeeCreatedAt,
    this.sourceUrl,
    this.extractedAt,
  });

  String? get displayImageUrl {
    final thumb = thumbnailUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) return thumb;
    if (images.isNotEmpty) return images.first;
    return null;
  }

  static String? _optionalString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static List<String> _parseImageUrls(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .map((item) => item.toString().trim())
          .where((url) => url.isNotEmpty)
          .toList();
    }
    if (raw is String) {
      return raw
          .split('\n')
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static String? _resolveThumbnailUrl(
    Map<String, dynamic> data,
    List<String> images,
  ) {
    return _optionalString(data['thumbnail_url']) ??
        _optionalString(data['image']) ??
        (images.isNotEmpty ? images.first : null);
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final images = _parseImageUrls(d['images']);
    final variationsImages = _parseImageUrls(d['variations_images']);

    return Product(
      productId: (d['product_id'] as num?)?.toInt() ?? 0,
      shopId: (d['shop_id'] as num?)?.toInt() ?? 0,
      categoryId: (d['category_id'] as num?)?.toInt(),
      name: d['name'] ?? '',
      url: d['url'] ?? '',
      thumbnailUrl: _resolveThumbnailUrl(d, images),
      images: images,
      variationsImages: variationsImages,
      price: (d['price'] as num?)?.toDouble() ?? 0,
      priceMax: (d['price_max'] as num?)?.toDouble(),
      priceMin: (d['price_min'] as num?)?.toDouble(),
      priceBeforeDiscount: (d['price_before_discount'] as num?)?.toDouble(),
      originalPrice: (d['original_price'] as num?)?.toDouble(),
      discount: (d['discount'] as num?)?.toInt() ?? 0,
      discountText: d['discount_text'],
      rating: (d['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (d['rating_count'] as num?)?.toInt() ?? 0,
      star1Count: (d['star_1_count'] as num?)?.toInt() ?? 0,
      star2Count: (d['star_2_count'] as num?)?.toInt() ?? 0,
      star3Count: (d['star_3_count'] as num?)?.toInt() ?? 0,
      star4Count: (d['star_4_count'] as num?)?.toInt() ?? 0,
      star5Count: (d['star_5_count'] as num?)?.toInt() ?? 0,
      soldCount: (d['sold_count'] as num?)?.toInt() ?? 0,
      soldCountText: d['sold_count_text'],
      monthlySoldCount: (d['monthly_sold_count'] as num?)?.toInt() ?? 0,
      likedCount: (d['liked_count'] as num?)?.toInt() ?? 0,
      colors: d['colors'],
      sizes: d['sizes'],
      variations: d['variations'],
      isAdult: d['is_adult'] ?? false,
      isServiceByShopee: d['is_service_by_shopee'] ?? false,
      isShopeeChoice: d['is_shopee_choice'] ?? false,
      isOnFlashSale: d['is_on_flash_sale'] ?? false,
      isOfficialShop: d['is_official_shop'] ?? false,
      isPreferredPlusSeller: d['is_preferred_plus_seller'] ?? false,
      isLowestPrice: d['is_lowest_price'] ?? false,
      isLiveStreamingPrice: d['is_live_streaming_price'],
      isMart: d['is_mart'] ?? false,
      canUseCod: d['can_use_cod'] ?? false,
      canUseWholesale: d['can_use_wholesale'] ?? false,
      hasLowestPriceGuarantee: d['has_lowest_price_guarantee'] ?? false,
      showFreeShipping: d['show_free_shipping'] ?? false,
      shopeeCreatedAt: (d['shopee_created_at'] as Timestamp?)?.toDate(),
      sourceUrl: d['source_url'],
      extractedAt: (d['extracted_at'] as Timestamp?)?.toDate(),
    );
  }

  static double _parsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  /// JSON từ script crawl Python (field `id`, `shopid`, price dạng string).
  factory Product.fromCrawlJson(Map<String, dynamic> d) {
    final images = _parseImageUrls(d['images']);
    final variationsImages = _parseImageUrls(d['variations_images']);

    return Product(
      productId: (d['id'] as num?)?.toInt() ?? 0,
      shopId: (d['shopid'] as num?)?.toInt() ?? 0,
      categoryId: (d['category'] as num?)?.toInt(),
      name: d['name']?.toString() ?? '',
      url: d['url']?.toString() ?? '',
      thumbnailUrl: _resolveThumbnailUrl(d, images),
      images: images,
      variationsImages: variationsImages,
      price: _parsePrice(d['price']),
      priceMax: _parsePrice(d['price_max']),
      priceMin: _parsePrice(d['price_min']),
      priceBeforeDiscount: _parsePrice(d['price_before_discount']),
      originalPrice: _parsePrice(d['original_price']),
      discount: (d['discount'] as num?)?.toInt() ?? 0,
      discountText: d['discount_text']?.toString(),
      rating: (d['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (d['rating_count'] as num?)?.toInt() ?? 0,
      star1Count: (d['star_1_count'] as num?)?.toInt() ?? 0,
      star2Count: (d['star_2_count'] as num?)?.toInt() ?? 0,
      star3Count: (d['star_3_count'] as num?)?.toInt() ?? 0,
      star4Count: (d['star_4_count'] as num?)?.toInt() ?? 0,
      star5Count: (d['star_5_count'] as num?)?.toInt() ?? 0,
      soldCount: (d['sold_count'] as num?)?.toInt() ?? 0,
      soldCountText: d['sold_count_text']?.toString(),
      monthlySoldCount: (d['monthly_sold_count'] as num?)?.toInt() ?? 0,
      likedCount: (d['liked_count'] as num?)?.toInt() ?? 0,
      colors: d['colors']?.toString(),
      sizes: d['sizes']?.toString(),
      variations: d['variations']?.toString(),
      isAdult: d['is_adult'] == true,
      isServiceByShopee: d['is_service_by_shopee'] == true,
      isShopeeChoice: d['is_shopee_choice'] == true,
      isOnFlashSale: d['is_on_flash_sale'] == true,
      isOfficialShop: d['is_official_shop'] == true,
      isPreferredPlusSeller: d['is_preferred_plus_seller'] == true,
      isLowestPrice: d['is_lowest_price'] == true,
      isLiveStreamingPrice: d['is_live_streaming_price'] as bool?,
      isMart: d['is_mart'] == true,
      canUseCod: d['can_use_cod'] != false,
      canUseWholesale: d['can_use_wholesale'] == true,
      hasLowestPriceGuarantee: d['has_lowest_price_guarantee'] == true,
      showFreeShipping: d['show_free_shipping'] == true,
      shopeeCreatedAt: _parseDate(d['created_time']),
      sourceUrl: d['source_url']?.toString(),
      extractedAt: _parseDate(d['extracted_at']),
    );
  }
}
