import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shopee_app/models/product.dart';

class CrawlApiService {
  static const defaultBaseUrl = 'http://127.0.0.1:8765';

  final String baseUrl;

  const CrawlApiService({this.baseUrl = defaultBaseUrl});

  Future<bool> isAvailable() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Product>> search({
    required String keyword,
    int limit = 60,
  }) async {
    final uri = Uri.parse('$baseUrl/api/search').replace(
      queryParameters: {
        'keyword': keyword,
        'limit': '$limit',
      },
    );

    final res = await http.get(uri).timeout(const Duration(minutes: 2));

    if (res.statusCode != 200) {
      String message = 'HTTP ${res.statusCode}';
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        message = body['detail']?.toString() ?? message;
      } catch (_) {}
      throw Exception(message);
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final items = body['products'] as List<dynamic>? ?? [];
    return items
        .map((e) => Product.fromCrawlJson(e as Map<String, dynamic>))
        .toList();
  }
}

class CrawlSearchResult {
  final List<Product> products;
  final Map<int, String> shopNames;

  const CrawlSearchResult({
    required this.products,
    required this.shopNames,
  });

  factory CrawlSearchResult.fromRawJson(Map<String, dynamic> body) {
    final items = body['products'] as List<dynamic>? ?? [];
    final products = <Product>[];
    final shopNames = <int, String>{};

    for (final raw in items) {
      final map = raw as Map<String, dynamic>;
      final product = Product.fromCrawlJson(map);
      products.add(product);
      final name = map['shop_name']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        shopNames[product.shopId] = name;
      }
    }

    return CrawlSearchResult(products: products, shopNames: shopNames);
  }
}

extension CrawlApiServiceExt on CrawlApiService {
  Future<CrawlSearchResult> searchWithShops({
    required String keyword,
    int limit = 60,
  }) async {
    final uri = Uri.parse('$baseUrl/api/search').replace(
      queryParameters: {
        'keyword': keyword,
        'limit': '$limit',
      },
    );

    final res = await http.get(uri).timeout(const Duration(minutes: 2));

    if (res.statusCode != 200) {
      String message = 'HTTP ${res.statusCode}';
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        message = body['detail']?.toString() ?? message;
      } catch (_) {}
      throw Exception(message);
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return CrawlSearchResult.fromRawJson(body);
  }
}
