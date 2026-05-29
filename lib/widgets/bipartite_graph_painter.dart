import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/models/graph_node.dart';

class BipartiteGraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final GraphNode? selectedNode;
  final GraphNode? hoveredNode;

  BipartiteGraphPainter({
    required this.nodes,
    required this.edges,
    this.selectedNode,
    this.hoveredNode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodeById = {for (final n in nodes) n.id: n};

    for (final edge in edges) {
      final source = nodeById[edge.sourceId];
      final target = nodeById[edge.targetId];
      if (source == null || target == null) continue;

      final isHighlighted = _isHighlightedEdge(edge, source, target);
      canvas.drawLine(
        source.position,
        target.position,
        Paint()
          ..color = isHighlighted
              ? AppColors.accent.withValues(alpha: 0.55)
              : AppColors.textSecondary.withValues(alpha: 0.18)
          ..strokeWidth = isHighlighted ? 1.4 : 1,
      );
    }

    for (final node in nodes) {
      final isSelected = selectedNode?.id == node.id;
      final isHovered = hoveredNode?.id == node.id;
      final isActive = isSelected || isHovered;

      if (isActive) {
        canvas.drawCircle(
          node.position,
          node.radius + 6,
          Paint()
            ..color = AppColors.accent.withValues(alpha: 0.25)
            ..style = PaintingStyle.fill,
        );
      }

      canvas.drawCircle(
        node.position,
        node.radius,
        Paint()
          ..color = node.color
          ..style = PaintingStyle.fill,
      );

      if (isActive || node.type == GraphNodeType.shop) {
        canvas.drawCircle(
          node.position,
          node.radius,
          Paint()
            ..color = isSelected
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? 2.5 : 1.2,
        );
      }
    }

    final labelNode = hoveredNode ?? selectedNode;
    if (labelNode != null) {
      _drawLabel(canvas, labelNode);
    }
  }

  bool _isHighlightedEdge(GraphEdge edge, GraphNode source, GraphNode target) {
    if (selectedNode == null && hoveredNode == null) return false;
    final active = selectedNode ?? hoveredNode!;
    return edge.sourceId == active.id ||
        edge.targetId == active.id ||
        source.id == active.id ||
        target.id == active.id;
  }

  void _drawLabel(Canvas canvas, GraphNode node) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    )..layout(maxWidth: 180);

    final labelWidth = textPainter.width + 12;
    final labelHeight = textPainter.height + 8;
    final dx = node.position.dx - labelWidth / 2;
    final dy = node.position.dy - node.radius - labelHeight - 8;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(dx, dy, labelWidth, labelHeight),
      const Radius.circular(6),
    );

    canvas.drawRRect(
      rect,
      Paint()..color = AppColors.card.withValues(alpha: 0.95),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    textPainter.paint(canvas, Offset(dx + 6, dy + 4));
  }

  @override
  bool shouldRepaint(covariant BipartiteGraphPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.edges != edges ||
        oldDelegate.selectedNode != selectedNode ||
        oldDelegate.hoveredNode != hoveredNode;
  }
}

GraphNode? hitTestGraphNode(Offset localPosition, List<GraphNode> nodes) {
  GraphNode? closest;
  var closestDist = double.infinity;

  for (final node in nodes) {
    final dist = (localPosition - node.position).distance;
    final hitRadius = node.radius + 6;
    if (dist <= hitRadius && dist < closestDist) {
      closest = node;
      closestDist = dist;
    }
  }

  return closest;
}

double graphZoomForNodeCount(int count) {
  if (count <= 30) return 1.0;
  if (count <= 60) return 0.85;
  return 0.7;
}

Offset graphPanOffset(int count, Size size) {
  return Offset(size.width * 0.02, size.height * 0.02);
}

double graphMinScale(int count) {
  return count > 80 ? 0.5 : 0.6;
}

double graphMaxScale(int count) {
  return math.max(2.5, graphMinScale(count) + 2);
}
