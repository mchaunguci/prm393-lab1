import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/models/graph_node.dart';
import 'package:shopee_app/models/product.dart';
import 'package:shopee_app/models/shop.dart';
import 'package:shopee_app/services/firestore_service.dart';
import 'package:shopee_app/utils/force_layout.dart';

class ShopProductGraphProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<Product> _products = [];
  List<Shop> _shops = [];
  List<GraphNode> _nodes = [];
  List<GraphEdge> _edges = [];
  bool _isLoading = true;
  String? _error;
  DateTime? _lastUpdated;

  String _searchQuery = '';
  String? _selectedLocation;
  bool _officialOnly = false;
  GraphColorMode _colorMode = GraphColorMode.official;
  GraphShopSizeMetric _shopSizeMetric = GraphShopSizeMetric.totalSold;
  GraphProductSizeMetric _productSizeMetric = GraphProductSizeMetric.monthlySold;

  GraphNode? _selectedNode;
  GraphNode? _hoveredNode;
  Size _layoutSize = Size.zero;

  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  List<GraphNode> get nodes => _nodes;
  List<GraphEdge> get edges => _edges;
  String get searchQuery => _searchQuery;
  String? get selectedLocation => _selectedLocation;
  bool get officialOnly => _officialOnly;
  GraphColorMode get colorMode => _colorMode;
  GraphShopSizeMetric get shopSizeMetric => _shopSizeMetric;
  GraphProductSizeMetric get productSizeMetric => _productSizeMetric;
  GraphNode? get selectedNode => _selectedNode;
  GraphNode? get hoveredNode => _hoveredNode;

  int get shopNodeCount =>
      _nodes.where((n) => n.type == GraphNodeType.shop).length;
  int get productNodeCount =>
      _nodes.where((n) => n.type == GraphNodeType.product).length;

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
      _lastUpdated = DateTime.now();
      _rebuildGraph();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    _searchQuery = value.trim();
    _selectedNode = null;
    _rebuildGraph();
    notifyListeners();
  }

  void setLocationFilter(String? location) {
    _selectedLocation = location;
    _selectedNode = null;
    _rebuildGraph();
    notifyListeners();
  }

  void setOfficialOnly(bool value) {
    _officialOnly = value;
    _selectedNode = null;
    _rebuildGraph();
    notifyListeners();
  }

  void setColorMode(GraphColorMode mode) {
    _colorMode = mode;
    _rebuildGraph();
    notifyListeners();
  }

  void setShopSizeMetric(GraphShopSizeMetric metric) {
    _shopSizeMetric = metric;
    _rebuildGraph();
    notifyListeners();
  }

  void setProductSizeMetric(GraphProductSizeMetric metric) {
    _productSizeMetric = metric;
    _rebuildGraph();
    notifyListeners();
  }

  void selectNode(GraphNode? node) {
    _selectedNode = node;
    notifyListeners();
  }

  void setHoveredNode(GraphNode? node) {
    if (_hoveredNode?.id == node?.id) return;
    _hoveredNode = node;
    notifyListeners();
  }

  void updateLayout(Size size) {
    if (size.width < 48 || size.height < 48) return;
    if (_nodes.isEmpty) return;

    final changed =
        (_layoutSize.width - size.width).abs() > 8 ||
        (_layoutSize.height - size.height).abs() > 8;
    if (!changed && _layoutSize != Size.zero) return;

    _layoutSize = size;
    ForceLayout.apply(nodes: _nodes, edges: _edges, size: size);
    notifyListeners();
  }

  void _rebuildGraph() {
    final shopById = {for (final s in _shops) s.shopId: s};
    final filteredProducts = _products.where(_matchesFilters).toList();
    if (filteredProducts.isEmpty) {
      _nodes = [];
      _edges = [];
      return;
    }

    final productsByShop = <int, List<Product>>{};
    for (final product in filteredProducts) {
      productsByShop.putIfAbsent(product.shopId, () => []).add(product);
    }

    var shopIds = productsByShop.keys.toSet();
    if (_officialOnly) {
      shopIds = shopIds.where((id) {
        final shop = shopById[id];
        final products = productsByShop[id] ?? [];
        return (shop?.isOfficial ?? false) ||
            products.any((p) => p.isOfficialShop);
      }).toSet();
    }

    if (_selectedLocation != null) {
      shopIds = shopIds.where((id) {
        final shop = shopById[id];
        return _locationGroup(_cleanLocation(shop?.shopLocation)) ==
            _selectedLocation;
      }).toSet();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      shopIds = shopIds.where((id) {
        final shop = shopById[id];
        final name = _shopName(shop, id).toLowerCase();
        if (name.contains(q)) return true;
        return (productsByShop[id] ?? [])
            .any((p) => p.name.toLowerCase().contains(q));
      }).toSet();
    }

    final visibleProducts = filteredProducts
        .where((p) => shopIds.contains(p.shopId))
        .toList();

    final shopMetrics = <int, double>{};
    for (final shopId in shopIds) {
      final products = visibleProducts.where((p) => p.shopId == shopId);
      shopMetrics[shopId] = _shopSizeMetric == GraphShopSizeMetric.totalSold
          ? products.fold<double>(0, (s, p) => s + p.soldCount)
          : products.fold<double>(
              0,
              (s, p) => s + p.price * p.soldCount,
            );
    }

    final productMetrics = visibleProducts.map((p) {
      if (_productSizeMetric == GraphProductSizeMetric.monthlySold) {
        return p.monthlySoldCount.toDouble();
      }
      return p.rating > 0 ? p.rating : 0.5;
    }).toList();

    final shopNodes = <GraphNode>[];
    for (final shopId in shopIds) {
      final shop = shopById[shopId];
      final products = visibleProducts.where((p) => p.shopId == shopId).toList();
      final location = _cleanLocation(shop?.shopLocation);
      final locationGroup = _locationGroup(location);
      final isOfficial =
          (shop?.isOfficial ?? false) ||
          products.any((p) => p.isOfficialShop);

      shopNodes.add(
        GraphNode(
          id: 'shop_$shopId',
          type: GraphNodeType.shop,
          label: _shopName(shop, shopId),
          metricValue: shopMetrics[shopId] ?? 0,
          radius: _scaleRadius(
            shopMetrics[shopId] ?? 0,
            shopMetrics.values,
            minR: 14,
            maxR: 36,
          ),
          color: _nodeColor(
            isOfficial: isOfficial,
            locationGroup: locationGroup,
          ),
          shopId: shopId,
          locationGroup: locationGroup,
          isOfficial: isOfficial,
        ),
      );
    }

    final productNodes = <GraphNode>[];
    for (var i = 0; i < visibleProducts.length; i++) {
      final product = visibleProducts[i];
      final shop = shopById[product.shopId];
      final location = _cleanLocation(shop?.shopLocation);
      final locationGroup = _locationGroup(location);

      productNodes.add(
        GraphNode(
          id: 'product_${product.productId}',
          type: GraphNodeType.product,
          label: _shortProductName(product.name),
          metricValue: productMetrics[i],
          radius: _scaleRadius(
            productMetrics[i],
            productMetrics,
            minR: 6,
            maxR: 18,
          ),
          color: _productColor(
            isOfficial: product.isOfficialShop,
            locationGroup: locationGroup,
          ),
          productId: product.productId,
          product: product,
          locationGroup: locationGroup,
          isOfficial: product.isOfficialShop,
        ),
      );
    }

    _nodes = [...shopNodes, ...productNodes];
    _edges = visibleProducts
        .map(
          (p) => GraphEdge(
            sourceId: 'shop_${p.shopId}',
            targetId: 'product_${p.productId}',
          ),
        )
        .toList();

    if (_layoutSize != Size.zero) {
      ForceLayout.apply(nodes: _nodes, edges: _edges, size: _layoutSize);
    }
  }

  bool _matchesFilters(Product product) {
    if (_officialOnly && !product.isOfficialShop) {
      // Keep product if its shop is official — checked later via shopIds.
    }
    return true;
  }

  Color _nodeColor({
    required bool isOfficial,
    required String locationGroup,
  }) {
    if (_colorMode == GraphColorMode.official) {
      return isOfficial ? AppColors.green : AppColors.textSecondary;
    }
    return _locationColor(locationGroup);
  }

  Color _productColor({
    required bool isOfficial,
    required String locationGroup,
  }) {
    if (_colorMode == GraphColorMode.official) {
      return isOfficial
          ? AppColors.blue.withValues(alpha: 0.85)
          : AppColors.cardLight;
    }
    return _locationColor(locationGroup).withValues(alpha: 0.75);
  }

  Color _locationColor(String group) {
    switch (group) {
      case 'TP. Hồ Chí Minh':
        return AppColors.blue;
      case 'Hà Nội':
        return AppColors.orange;
      case 'Tỉnh khác':
        return AppColors.purple;
      default:
        return AppColors.textSecondary;
    }
  }

  double _scaleRadius(
    double value,
    Iterable<double> allValues, {
    required double minR,
    required double maxR,
  }) {
    final values = allValues.where((v) => v > 0).toList();
    if (values.isEmpty) return (minR + maxR) / 2;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    if (maxV == minV) return (minR + maxR) / 2;
    final t = ((value - minV) / (maxV - minV)).clamp(0.0, 1.0);
    return minR + t * (maxR - minR);
  }

  String _shopName(Shop? shop, int shopId) {
    final name = shop?.shopName.trim();
    if (name == null || name.isEmpty) return 'Shop #$shopId';
    return name;
  }

  String _shortProductName(String name) {
    final trimmed = name.trim();
    if (trimmed.length <= 28) return trimmed;
    return '${trimmed.substring(0, 25)}...';
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
