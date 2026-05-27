import 'package:flutter/foundation.dart';
import 'package:shopee_app/models/product.dart';
import 'package:shopee_app/models/shop.dart';
import 'package:shopee_app/services/firestore_service.dart';

class PriceCompareFilter {
  final bool? isOfficialShop;
  final bool? isLowestPrice;
  final double? minRating;
  final bool? canUseCod;

  const PriceCompareFilter({
    this.isOfficialShop,
    this.isLowestPrice,
    this.minRating,
    this.canUseCod,
  });

  PriceCompareFilter copyWith({
    Object? isOfficialShop = _sentinel,
    Object? isLowestPrice = _sentinel,
    Object? minRating = _sentinel,
    Object? canUseCod = _sentinel,
  }) {
    return PriceCompareFilter(
      isOfficialShop: isOfficialShop == _sentinel
          ? this.isOfficialShop
          : isOfficialShop as bool?,
      isLowestPrice: isLowestPrice == _sentinel
          ? this.isLowestPrice
          : isLowestPrice as bool?,
      minRating:
          minRating == _sentinel ? this.minRating : minRating as double?,
      canUseCod:
          canUseCod == _sentinel ? this.canUseCod : canUseCod as bool?,
    );
  }

  bool get isAnyActive =>
      isOfficialShop == true ||
      isLowestPrice == true ||
      minRating != null ||
      canUseCod == true;

  static const _sentinel = Object();
}

class PriceCompareProvider extends ChangeNotifier {
  final _service = FirestoreService();

  List<Product> _allProducts = [];
  Map<int, Shop> _shopById = {};
  Map<String, List<Product>> _groupedByModel = {};

  bool _isLoading = true;
  String? _error;
  DateTime? _lastUpdated;
  String _selectedModel = '';
  String _searchQuery = '';
  PriceCompareFilter _filter = const PriceCompareFilter();
  int _currentPage = 0;

  static const int pageSize = 10;

  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  String get selectedModel => _selectedModel;
  String get searchQuery => _searchQuery;
  PriceCompareFilter get filter => _filter;
  int get currentPage => _currentPage;

  int get totalPages {
    final n = filteredProducts.length;
    if (n == 0) return 1;
    return (n + pageSize - 1) ~/ pageSize;
  }

  List<Product> get pagedProducts {
    final all = filteredProducts;
    if (all.isEmpty) return const [];
    final start = (_currentPage * pageSize).clamp(0, all.length);
    final end = (start + pageSize).clamp(0, all.length);
    return all.sublist(start, end);
  }

  void setPage(int page) {
    final clamped = page.clamp(0, totalPages - 1);
    if (clamped == _currentPage) return;
    _currentPage = clamped;
    notifyListeners();
  }

  static final _modelRegex = RegExp(
    r'RTX\s*(5090|5080|5070\s*Ti|5070|5060\s*Ti|5060|5050)',
    caseSensitive: false,
  );

  static const _modelOrder = [
    'RTX 5050',
    'RTX 5060',
    'RTX 5060 Ti',
    'RTX 5070',
    'RTX 5070 Ti',
    'RTX 5080',
    'RTX 5090',
  ];

  static String? _extractModel(String name) {
    final match = _modelRegex.firstMatch(name);
    if (match == null) return null;
    final raw = match.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ');
    return 'RTX $raw';
  }

  List<String> get modelGroups {
    final present = _groupedByModel.keys.toSet();
    return _modelOrder.where(present.contains).toList();
  }

  List<Product> get filteredProducts {
    var list = List<Product>.from(_groupedByModel[_selectedModel] ?? []);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        final shopName = _shopById[p.shopId]?.shopName ?? '';
        return p.name.toLowerCase().contains(q) ||
            shopName.toLowerCase().contains(q);
      }).toList();
    }

    if (_filter.isOfficialShop == true) {
      list = list.where((p) => p.isOfficialShop).toList();
    }
    if (_filter.isLowestPrice == true) {
      list = list.where((p) => p.isLowestPrice).toList();
    }
    if (_filter.minRating != null) {
      final threshold = _filter.minRating!;
      list = list.where((p) => p.rating >= threshold).toList();
    }
    if (_filter.canUseCod == true) {
      list = list.where((p) => p.canUseCod).toList();
    }

    list.sort((a, b) => a.price.compareTo(b.price));
    return list;
  }

  Product? get bestDeal {
    final pool = _groupedByModel[_selectedModel];
    if (pool == null || pool.isEmpty) return null;

    final flagged = pool.where((p) => p.isLowestPrice).toList();
    if (flagged.isNotEmpty) {
      return flagged.reduce((a, b) => _score(a) >= _score(b) ? a : b);
    }

    return pool.reduce((a, b) {
      final cmp = _score(b).compareTo(_score(a));
      if (cmp != 0) return cmp > 0 ? b : a;
      return a.price <= b.price ? a : b;
    });
  }

  double _score(Product p) => p.rating * p.monthlySoldCount;

  double get priceMin {
    final p = filteredProducts;
    if (p.isEmpty) return 0;
    return p.map((x) => x.price).reduce((a, b) => a < b ? a : b);
  }

  double get priceMax {
    final p = filteredProducts;
    if (p.isEmpty) return 0;
    return p.map((x) => x.price).reduce((a, b) => a > b ? a : b);
  }

  double get avgPrice {
    final p = filteredProducts;
    if (p.isEmpty) return 0;
    return p.map((x) => x.price).reduce((a, b) => a + b) / p.length;
  }

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getProducts(),
        _service.getShops(),
      ]);
      _allProducts = results[0] as List<Product>;
      final shops = results[1] as List<Shop>;
      _shopById = {for (final s in shops) s.shopId: s};
      _buildGroups();
      final groups = modelGroups;
      if (_selectedModel.isEmpty || !groups.contains(_selectedModel)) {
        _selectedModel = groups.isNotEmpty ? groups.first : '';
      }
      _lastUpdated = DateTime.now();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _buildGroups() {
    _groupedByModel = {};
    for (final p in _allProducts) {
      final model = _extractModel(p.name);
      if (model != null) {
        _groupedByModel.putIfAbsent(model, () => []).add(p);
      }
    }
  }

  void selectModel(String model) {
    if (_selectedModel == model) return;
    _selectedModel = model;
    _currentPage = 0;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query.trim();
    _currentPage = 0;
    notifyListeners();
  }

  void setFilter(PriceCompareFilter f) {
    _filter = f;
    _currentPage = 0;
    notifyListeners();
  }

  void clearFilter() {
    _filter = const PriceCompareFilter();
    _currentPage = 0;
    notifyListeners();
  }

  String shopNameFor(int shopId) {
    return _shopById[shopId]?.shopName ?? 'Shop #$shopId';
  }

  bool isOfficialShopId(int shopId) {
    return _shopById[shopId]?.isOfficial ?? false;
  }
}
