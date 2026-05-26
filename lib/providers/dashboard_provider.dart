import 'package:flutter/foundation.dart';
import 'package:shopee_app/models/product.dart';
import 'package:shopee_app/models/shop.dart';
import 'package:shopee_app/models/category.dart' as models;
import 'package:shopee_app/services/firestore_service.dart';

class DashboardProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<Product> _products = [];
  List<Shop> _shops = [];
  List<models.Category> _categories = [];
  bool _isLoading = true;
  String? _error;
  DateTime? _lastUpdated;

  List<Product> get products => _products;
  List<Shop> get shops => _shops;
  List<models.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;

  int get totalProducts => _products.length;
  int get totalShops => _shops.length;
  int get totalCategories => _categories.length;

  double get avgPrice {
    if (_products.isEmpty) return 0;
    return _products.map((p) => p.price).reduce((a, b) => a + b) / _products.length;
  }

  double get avgRating {
    final rated = _products.where((p) => p.ratingCount > 0).toList();
    if (rated.isEmpty) return 0;
    return rated.map((p) => p.rating).reduce((a, b) => a + b) / rated.length;
  }

  double get avgDiscount {
    final discounted = _products.where((p) => p.discount > 0).toList();
    if (discounted.isEmpty) return 0;
    return discounted.map((p) => p.discount.toDouble()).reduce((a, b) => a + b) / discounted.length;
  }

  List<Product> get topBySold {
    final sorted = List<Product>.from(_products)
      ..sort((a, b) => b.monthlySoldCount.compareTo(a.monthlySoldCount));
    return sorted.take(5).toList();
  }

  List<Product> get topByDiscount {
    final sorted = List<Product>.from(_products.where((p) => p.discount > 0))
      ..sort((a, b) => b.discount.compareTo(a.discount));
    return sorted.take(5).toList();
  }

  Map<String, int> get locationDistribution {
    final map = <String, int>{};
    for (final shop in _shops) {
      final loc = shop.shopLocation ?? 'Không rõ';
      map[loc] = (map[loc] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> get priceDistribution {
    final ranges = <String, int>{
      '< 500K': 0,
      '500K - 2M': 0,
      '2M - 10M': 0,
      '10M - 50M': 0,
      '> 50M': 0,
    };
    for (final p in _products) {
      if (p.price < 500000) {
        ranges['< 500K'] = ranges['< 500K']! + 1;
      } else if (p.price < 2000000) {
        ranges['500K - 2M'] = ranges['500K - 2M']! + 1;
      } else if (p.price < 10000000) {
        ranges['2M - 10M'] = ranges['2M - 10M']! + 1;
      } else if (p.price < 50000000) {
        ranges['10M - 50M'] = ranges['10M - 50M']! + 1;
      } else {
        ranges['> 50M'] = ranges['> 50M']! + 1;
      }
    }
    return ranges;
  }

  String shopNameFor(int shopId) {
    final shop = _shops.where((s) => s.shopId == shopId).firstOrNull;
    return shop?.shopName ?? 'N/A';
  }

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getProducts(),
        _service.getShops(),
        _service.getCategories(),
      ]);
      _products = results[0] as List<Product>;
      _shops = results[1] as List<Shop>;
      _categories = results[2] as List<models.Category>;
      _lastUpdated = DateTime.now();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
