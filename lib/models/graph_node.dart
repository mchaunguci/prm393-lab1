import 'package:flutter/material.dart';
import 'package:shopee_app/models/product.dart';

enum GraphNodeType { shop, product }

enum GraphColorMode { official, location }

enum GraphShopSizeMetric { totalSold, revenue }

enum GraphProductSizeMetric { monthlySold, rating }

class GraphNode {
  final String id;
  final GraphNodeType type;
  final String label;
  final double metricValue;
  final double radius;
  final Color color;
  final int? shopId;
  final int? productId;
  final Product? product;
  final String? locationGroup;
  final bool isOfficial;

  Offset position;

  GraphNode({
    required this.id,
    required this.type,
    required this.label,
    required this.metricValue,
    required this.radius,
    required this.color,
    this.shopId,
    this.productId,
    this.product,
    this.locationGroup,
    this.isOfficial = false,
    this.position = Offset.zero,
  });
}

class GraphEdge {
  final String sourceId;
  final String targetId;

  const GraphEdge({required this.sourceId, required this.targetId});
}
