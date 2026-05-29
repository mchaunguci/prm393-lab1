import 'package:flutter/material.dart';
import 'package:shopee_app/models/product.dart';
import 'package:shopee_app/models/shop.dart';
import 'package:shopee_app/services/firestore_service.dart';

class ProductListProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<Product> _allProducts = [];
  List<Shop> _shops = [];
  bool _isLoading = true;
  String? _error;

  //Filter state
  String _searchQuery = '';
  String? _selectedShop; // shop_id as string, null = tất cả
  String? _selectedLocation;
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  bool? _isOfficialShop;
  bool? _isLowestPrice;
  bool? _isShopeeChoice;

  //sort state
  String _sortBy = 'price'; // price, rating, sold, discount
  bool _sortAsc = true;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Shop> get shops => _shops;
  String get searchQuery => _searchQuery;
  String? get selectedShop => _selectedShop;
  String? get selectedLocation => _selectedLocation;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  double? get minRating => _minRating;
  bool? get isOfficialShop => _isOfficialShop;
  bool? get isLowestPrice => _isLowestPrice;
  bool? get isShopeeChoice => _isShopeeChoice;
  String get sortBy => _sortBy;
  bool get sortAsc => _sortAsc;
  int get totalProducts => _allProducts.length;

  //filter + sorted
  List<Product> get products {
    //tao 1 list copy cua _allProducts
    var result = List<Product>.from(_allProducts);

    //search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((p) => p.name.toLowerCase().contains(query))
          .toList();
    }

    //shop filter
    if (_selectedShop != null) {
      final shopId = int.parse(_selectedShop!);
      result = result.where((p) => p.shopId == shopId).toList();
    }

    //location filter
    if (_selectedLocation != null) {
      final shopIds = _shops
          .where((s) => s.shopLocation == _selectedLocation)
          .map((s) => s.shopId)
          .toSet();
      result = result.where((p) => shopIds.contains(p.shopId)).toList();
    }

    //price filter
    if (_minPrice != null) {
      result = result.where((p) => p.price >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      result = result.where((p) => p.price <= _maxPrice!).toList();
    }

    //rating filter
    if (_minRating != null) {
      result = result.where((p) => p.rating >= _minRating!).toList();
    }

    //filter by flags
    if (_isOfficialShop == true) {
      result = result.where((p) => p.isOfficialShop).toList();
    }
    if (_isLowestPrice == true) {
      result = result.where((p) => p.isLowestPrice).toList();
    }
    if (_isShopeeChoice == true) {
      result = result.where((p) => p.isShopeeChoice).toList();
    }

    //sort
    result.sort((a, b) {
      int compare;
      switch (_sortBy) {
        case 'price':
          compare = a.price.compareTo(b.price);
        case 'rating':
          compare = a.rating.compareTo(b.rating);
        case 'sold':
          compare = a.monthlySoldCount.compareTo(b.monthlySoldCount);
        case 'discount':
          compare = a.discount.compareTo(b.discount);
        default:
          compare = a.price.compareTo(b.price);
      }
      return _sortAsc ? compare : -compare;
    });
    return result;
  }

  //Locations tu shops
  List<String> get locations {
    return _shops
        .map((s) => s.shopLocation ?? 'Không rõ') //
        .toSet()
        .toList()
      ..sort(); //.. return the list
  }

  String shopNameFor(int shopId) {
    final shop = _shops.where((s) => s.shopId == shopId).firstOrNull;
    return shop?.shopName ?? 'N/A';
  }

  //Actions -- State modified methods
  void setSearch(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setShopFilter(String? shopId) {
    _selectedShop = shopId;
    notifyListeners();
  }

  void setLocationFilter(String? location) {
    _selectedLocation = location;
    notifyListeners();
  }

  void setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    notifyListeners();
  }

  void setMinRating(double? rating) {
    _minRating = rating;
    notifyListeners();
  }

  void setFlags({bool? official, bool? lowest, bool? shopeeChoice}) {
    _isOfficialShop = official;
    _isLowestPrice = lowest;
    _isShopeeChoice = shopeeChoice;
    notifyListeners();
  }

  void setSort(String field) {
    switch (field) {
      case 'price_asc':
        _sortBy = 'price';
        _sortAsc = true;
      case 'price_desc':
        _sortBy = 'price';
        _sortAsc = false;
      default:
        _sortBy = field;
        _sortAsc = false;
    }
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedShop = null;
    _selectedLocation = null;
    _minPrice = null;
    _maxPrice = null;
    _minRating = null;
    _isOfficialShop = null;
    _isLowestPrice = null;
    _isShopeeChoice = null;
    notifyListeners();
  }

  //load data from firestore
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([ //lay thoi gian cua thang lau nhat
        _service.getProducts(),
        _service.getShops(),
      ]);
      _allProducts = results[0] as List<Product>;
      _shops = results[1] as List<Shop>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
