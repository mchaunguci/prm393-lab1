import 'package:flutter/foundation.dart';
import 'package:shopee_app/models/product.dart';
import 'package:shopee_app/models/shop.dart';
import 'package:shopee_app/services/crawl_api_service.dart';
import 'package:shopee_app/services/firestore_service.dart';

enum KeywordSearchSource { liveApi, firestore }

class KeywordSearchProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  final CrawlApiService _crawlApi = const CrawlApiService();

  List<Product> _allProducts = [];
  List<Shop> _shops = [];
  List<Product> _results = [];
  final Map<int, String> _liveShopNames = {};
  String _keyword = '';
  bool _isLoading = true;
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _apiOnline = false;
  String? _error;
  KeywordSearchSource _source = KeywordSearchSource.liveApi;

  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get hasSearched => _hasSearched;
  bool get apiOnline => _apiOnline;
  String? get error => _error;
  String get keyword => _keyword;
  List<Product> get results => _results;
  KeywordSearchSource get source => _source;

  int get resultCount => _results.length;

  int get shopCount => _results.map((p) => p.shopId).toSet().length;

  double get avgPrice {
    if (_results.isEmpty) return 0;
    return _results.map((p) => p.price).reduce((a, b) => a + b) / _results.length;
  }

  double get minPrice {
    if (_results.isEmpty) return 0;
    return _results.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  }

  double get maxPrice {
    if (_results.isEmpty) return 0;
    return _results.map((p) => p.price).reduce((a, b) => a > b ? a : b);
  }

  double get avgRating {
    final rated = _results.where((p) => p.ratingCount > 0).toList();
    if (rated.isEmpty) return 0;
    return rated.map((p) => p.rating).reduce((a, b) => a + b) / rated.length;
  }

  double get avgDiscount {
    final discounted = _results.where((p) => p.discount > 0).toList();
    if (discounted.isEmpty) return 0;
    return discounted.map((p) => p.discount.toDouble()).reduce((a, b) => a + b) /
        discounted.length;
  }

  int get officialShopCount =>
      _results.where((p) => p.isOfficialShop).length;

  int get totalSold =>
      _results.fold(0, (sum, p) => sum + p.soldCount);

  String shopNameFor(int shopId) {
    final live = _liveShopNames[shopId];
    if (live != null && live.isNotEmpty) return live;
    final shop = _shops.where((s) => s.shopId == shopId).firstOrNull;
    return shop?.shopName ?? 'Shop #$shopId';
  }

  Future<void> refreshApiStatus() async {
    _apiOnline = await _crawlApi.isAvailable();
    notifyListeners();
  }

  void setSource(KeywordSearchSource source) {
    if (_source == source) return;
    _source = source;
    _results = [];
    _liveShopNames.clear();
    _hasSearched = false;
    _error = null;
    notifyListeners();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getProducts(),
        _service.getShops(),
        _crawlApi.isAvailable(),
      ]);
      _allProducts = results[0] as List<Product>;
      _shops = results[1] as List<Shop>;
      _apiOnline = results[2] as bool;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String keyword) async {
    _keyword = keyword.trim();
    _hasSearched = true;
    _error = null;
    _liveShopNames.clear();

    if (_keyword.isEmpty) {
      _results = [];
      notifyListeners();
      return;
    }

    if (_source == KeywordSearchSource.liveApi) {
      await _searchLive();
    } else {
      _searchFirestore();
    }
  }

  Future<void> _searchLive() async {
    _isSearching = true;
    notifyListeners();

    try {
      final result = await _crawlApi.searchWithShops(
        keyword: _keyword,
        limit: 60,
      );
      _results = result.products
        ..sort((a, b) => a.price.compareTo(b.price));
      _liveShopNames.addAll(result.shopNames);
      _apiOnline = true;
    } catch (e) {
      _error = e.toString();
      _results = [];
      _apiOnline = await _crawlApi.isAvailable();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void _searchFirestore() {
    _results = _allProducts.where((p) => _matchesKeyword(p.name, _keyword)).toList()
      ..sort((a, b) => a.price.compareTo(b.price));
    notifyListeners();
  }

  bool _matchesKeyword(String name, String keyword) {
    final query = keyword.toLowerCase().trim();
    if (query.isEmpty) return false;

    final nameLower = name.toLowerCase();
    if (nameLower.contains(query)) return true;

    final compactName = nameLower.replaceAll(RegExp(r'\s+'), '');
    final compactQuery = query.replaceAll(RegExp(r'\s+'), '');
    if (compactQuery.isNotEmpty && compactName.contains(compactQuery)) {
      return true;
    }

    final parts = query.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.every(nameLower.contains);
  }

  void clear() {
    _keyword = '';
    _results = [];
    _liveShopNames.clear();
    _hasSearched = false;
    _error = null;
    notifyListeners();
  }
}
