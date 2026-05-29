import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shopee_app/models/graph_node.dart';

class ForceLayout {
  ForceLayout._();

  static void apply({
    required List<GraphNode> nodes,
    required List<GraphEdge> edges,
    required Size size,
    int iterations = 120,
  }) {
    if (nodes.isEmpty) return;
    if (size.width < 48 || size.height < 48) return;

    final random = math.Random(42);
    final positions = <String, Offset>{};
    final center = Offset(size.width / 2, size.height / 2);
    final spread = math.min(size.width, size.height) * 0.35;

    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node.type == GraphNodeType.shop) {
        final angle = (i / nodes.length) * math.pi * 2;
        positions[node.id] = center + Offset(
          math.cos(angle) * spread * 0.3,
          math.sin(angle) * spread * 0.3,
        );
      } else {
        positions[node.id] = center + Offset(
          (random.nextDouble() - 0.5) * spread * 1.6,
          (random.nextDouble() - 0.5) * spread * 1.6,
        );
      }
    }

    final nodeById = {for (final n in nodes) n.id: n};

    for (var iter = 0; iter < iterations; iter++) {
      final cooling = 1 - iter / iterations;
      final displacements = {for (final n in nodes) n.id: Offset.zero};

      for (var i = 0; i < nodes.length; i++) {
        for (var j = i + 1; j < nodes.length; j++) {
          final a = nodes[i];
          final b = nodes[j];
          final delta = positions[a.id]! - positions[b.id]!;
          final distance = math.max(delta.distance, 1.0);
          final minDist = _effectiveRadius(a, size) + _effectiveRadius(b, size) + 8;
          final repulsion = 800 * cooling / (distance * distance);
          final sameType = a.type == b.type;
          final force = delta / distance * repulsion * (sameType ? 1.4 : 1.0);
          displacements[a.id] = displacements[a.id]! + force;
          displacements[b.id] = displacements[b.id]! - force;

          if (distance < minDist) {
            final push = (minDist - distance) / 2;
            final pushForce = delta / distance * push;
            displacements[a.id] = displacements[a.id]! + pushForce;
            displacements[b.id] = displacements[b.id]! - pushForce;
          }
        }
      }

      for (final edge in edges) {
        final source = positions[edge.sourceId];
        final target = positions[edge.targetId];
        if (source == null || target == null) continue;

        final delta = target - source;
        final distance = math.max(delta.distance, 1.0);
        final ideal = 80 + (nodeById[edge.sourceId]?.radius ?? 10);
        final attraction = (distance - ideal) * 0.04 * cooling;
        final force = delta / distance * attraction;
        displacements[edge.sourceId] =
            displacements[edge.sourceId]! + force;
        displacements[edge.targetId] =
            displacements[edge.targetId]! - force;
      }

      for (final node in nodes) {
        final toCenter = center - positions[node.id]!;
        displacements[node.id] =
            displacements[node.id]! + toCenter * 0.002 * cooling;
      }

      for (final node in nodes) {
        final displacement = displacements[node.id]!;
        final capped = _cap(displacement, 10 * cooling + 0.5);
        positions[node.id] = _clampToBounds(
          positions[node.id]! + capped,
          node,
          size,
        );
      }
    }

    for (final node in nodes) {
      node.position = positions[node.id] ?? center;
    }
  }

  static double _effectiveRadius(GraphNode node, Size size) {
    const padding = 12.0;
    final maxR = math.min(size.width, size.height) / 2 - padding;
    if (maxR <= 4) return 4;
    return math.min(node.radius, maxR);
  }

  static Offset _cap(Offset v, double max) {
    if (v.distance <= max) return v;
    return v / v.distance * max;
  }

  static Offset _clampToBounds(Offset p, GraphNode node, Size size) {
    const padding = 12.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = _effectiveRadius(node, size);
    final minX = r + padding;
    final maxX = size.width - r - padding;
    final minY = r + padding;
    final maxY = size.height - r - padding;

    return Offset(
      _safeClamp(p.dx, minX, maxX, cx),
      _safeClamp(p.dy, minY, maxY, cy),
    );
  }

  /// Avoids [double.clamp] when bounds are invalid or value is non-finite.
  static double _safeClamp(double value, double min, double max, double fallback) {
    if (!value.isFinite) return fallback;
    if (min > max) return fallback;
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
