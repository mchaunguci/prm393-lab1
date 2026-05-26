import 'package:flutter/foundation.dart';
import 'package:shopee_app/models/product.dart';
import 'package:shopee_app/models/shop.dart';
import 'package:shopee_app/models/shop_analytics_item.dart';
import 'package:shopee_app/services/firestore_service.dart';

enum ShopSortOption {
  productCount,
  totalSold,
  monthlySold,
  averageRating,
  averagePrice,
  revenueEstimate,
}

class ShopAnalysisProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<Product> _products = [];
  List<Shop> _shops = [];
  List<ShopAnalyticsItem> _allShopStats = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String? _selectedLocation;
  ShopSortOption _sortOption = ShopSortOption.productCount;
  ShopAnalyticsItem? _selectedShop;
  DateTime? _lastUpdated;

  List<Product> get products => _products;
  List<Shop> get shops => _shops;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorMessage => _error;
  String get searchQuery => _searchQuery;
  String? get selectedLocation => _selectedLocation;
  ShopSortOption get sortOption => _sortOption;
  ShopAnalyticsItem? get selectedShop => _selectedShop;
  DateTime? get lastUpdated => _lastUpdated;

  List<ShopAnalyticsItem> get shopStats {
    final filtered = _allShopStats.where((shop) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          shop.shopName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesLocation =
          _selectedLocation == null || shop.locationGroup == _selectedLocation;
      return matchesSearch && matchesLocation;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortOption) {
        case ShopSortOption.productCount:
          return b.productCount.compareTo(a.productCount);
        case ShopSortOption.totalSold:
          return b.totalSold.compareTo(a.totalSold);
        case ShopSortOption.monthlySold:
          return b.monthlySold.compareTo(a.monthlySold);
        case ShopSortOption.averageRating:
          return b.averageRating.compareTo(a.averageRating);
        case ShopSortOption.averagePrice:
          return b.averagePrice.compareTo(a.averagePrice);
        case ShopSortOption.revenueEstimate:
          return b.totalRevenueEstimate.compareTo(a.totalRevenueEstimate);
      }
    });

    return filtered;
  }

  List<ShopAnalyticsItem> get shopAnalytics => shopStats;

  int get totalShops => _allShopStats.length;
  int get totalProducts => _products.length;
  int get officialShopCount =>
      _allShopStats.where((shop) => shop.isOfficial).length;
  int get totalSold =>
      _allShopStats.fold(0, (sum, shop) => sum + shop.totalSold);

  double get averageShopRating {
    final rated = _allShopStats
        .where((shop) => shop.averageRating > 0)
        .toList();
    if (rated.isEmpty) return 0;
    return rated.map((shop) => shop.averageRating).reduce((a, b) => a + b) /
        rated.length;
  }

  String get topLocation {
    final entries = locationDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.isEmpty ? 'Không rõ' : entries.first.key;
  }

  List<ShopAnalyticsItem> get topByProductCount {
    final sorted = List<ShopAnalyticsItem>.from(shopStats)
      ..sort((a, b) => b.productCount.compareTo(a.productCount));
    return sorted.take(5).toList();
  }

  List<ShopAnalyticsItem> get topBySold {
    final sorted = List<ShopAnalyticsItem>.from(shopStats)
      ..sort((a, b) => b.totalSold.compareTo(a.totalSold));
    return sorted.take(5).toList();
  }

  Map<String, int> get locationDistribution {
    final map = <String, int>{};
    for (final shop in shopStats) {
      map[shop.locationGroup] = (map[shop.locationGroup] ?? 0) + 1;
    }
    return map;
  }

  List<String> get locationOptions => const [
    'TP. Hồ Chí Minh',
    'Hà Nội',
    'Tỉnh khác',
    'Không rõ',
  ];

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getProducts(),
        _service.getShops(),
      ]);
      _products = results[0] as List<Product>;
      _shops = results[1] as List<Shop>;
      _allShopStats = _buildShopStats();
      _lastUpdated = DateTime.now();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchShop(String keyword) {
    _searchQuery = keyword.trim();
    notifyListeners();
  }

  void filterByLocation(String? location) {
    _selectedLocation = location;
    notifyListeners();
  }

  void sortBy(ShopSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void selectShop(ShopAnalyticsItem shop) {
    _selectedShop = shop;
    notifyListeners();
  }

  void clearSelectedShop() {
    _selectedShop = null;
    notifyListeners();
  }

  List<ShopAnalyticsItem> _buildShopStats() {
    final shopById = {for (final shop in _shops) shop.shopId: shop};
    final productsByShop = <int, List<Product>>{};

    for (final product in _products) {
      productsByShop.putIfAbsent(product.shopId, () => []).add(product);
    }

    final shopIds = <int>{...shopById.keys, ...productsByShop.keys};

    return shopIds.map((shopId) {
      final shop = shopById[shopId];
      final products = productsByShop[shopId] ?? <Product>[];
      final productCount = products.length;
      final ratedProducts = products
          .where((product) => product.rating > 0)
          .toList();
      final location = _cleanLocation(shop?.shopLocation);

      final totalSold = products.fold<int>(
        0,
        (sum, product) => sum + product.soldCount,
      );
      final monthlySold = products.fold<int>(
        0,
        (sum, product) => sum + product.monthlySoldCount,
      );
      final totalRatingCount = products.fold<int>(
        0,
        (sum, product) => sum + product.ratingCount,
      );
      final totalRevenue = products.fold<double>(
        0,
        (sum, product) => sum + product.price * product.soldCount,
      );

      return ShopAnalyticsItem(
        shopId: shopId,
        shopName: _shopName(shop, shopId),
        location: location,
        locationGroup: _locationGroup(location),
        isOfficial:
            (shop?.isOfficial ?? false) ||
            products.any((product) => product.isOfficialShop),
        productCount: productCount,
        totalSold: totalSold,
        monthlySold: monthlySold,
        averageRating: ratedProducts.isEmpty
            ? 0
            : ratedProducts
                      .map((product) => product.rating)
                      .reduce((a, b) => a + b) /
                  ratedProducts.length,
        totalRatingCount: totalRatingCount,
        averagePrice: productCount == 0
            ? 0
            : products.map((product) => product.price).reduce((a, b) => a + b) /
                  productCount,
        totalRevenueEstimate: totalRevenue,
        averageDiscount: productCount == 0
            ? 0
            : products
                      .map((product) => product.discount.toDouble())
                      .reduce((a, b) => a + b) /
                  productCount,
        products: products,
      );
    }).toList()..sort((a, b) => b.productCount.compareTo(a.productCount));
  }

  String _shopName(Shop? shop, int shopId) {
    final name = shop?.shopName.trim();
    if (name == null || name.isEmpty) return 'Unknown Shop #$shopId';
    return name;
  }

  String _cleanLocation(String? value) {
    final location = value?.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (location == null || location.isEmpty) return 'Không rõ';
    return location;
  }

  String _locationGroup(String location) {
    final lower = location.toLowerCase();
    if (location == 'Không rõ') return 'Không rõ';
    if (lower.contains('hồ chí minh') ||
        lower.contains('ho chi minh') ||
        lower.contains('tp.hcm') ||
        lower.contains('tp hcm') ||
        lower.contains('hcm')) {
      return 'TP. Hồ Chí Minh';
    }
    if (lower.contains('hà nội') || lower.contains('ha noi')) {
      return 'Hà Nội';
    }
    return 'Tỉnh khác';
  }
}
