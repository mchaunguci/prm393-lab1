import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/core/utils/formatters.dart';
import 'package:shopee_app/models/graph_node.dart';

class BipartiteGraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final GraphNode? selectedNode;
  final GraphNode? hoveredNode;
  final bool showAllLabels;
  final Set<String> matchedNodeIds;

  BipartiteGraphPainter({
    required this.nodes,
    required this.edges,
    this.selectedNode,
    this.hoveredNode,
    this.showAllLabels = false,
    this.matchedNodeIds = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodeById = {for (final n in nodes) n.id: n};

    // Xác định tập node "đang được tập trung" (focus) để làm mờ phần còn lại:
    // - Ưu tiên node đang chọn + hàng xóm trực tiếp.
    // - Nếu không có node chọn nhưng đang tìm kiếm thì focus theo kết quả khớp.
    Set<String>? focusIds;
    if (selectedNode != null) {
      focusIds = {selectedNode!.id};
      for (final e in edges) {
        if (e.sourceId == selectedNode!.id) focusIds.add(e.targetId);
        if (e.targetId == selectedNode!.id) focusIds.add(e.sourceId);
      }
    } else if (matchedNodeIds.isNotEmpty) {
      focusIds = matchedNodeIds;
    }

    bool isDimmed(String id) => focusIds != null && !focusIds.contains(id);

    // Edges trước, node sau (node đè lên đường nối).
    for (final edge in edges) {
      final source = nodeById[edge.sourceId];
      final target = nodeById[edge.targetId];
      if (source == null || target == null) continue;

      final edgeFocused = focusIds != null &&
          focusIds.contains(source.id) &&
          focusIds.contains(target.id);
      final edgeDimmed =
          focusIds != null && (isDimmed(source.id) || isDimmed(target.id));

      final Color color;
      final double width;
      if (edgeDimmed) {
        color = AppColors.textSecondary.withValues(alpha: 0.05);
        width = 1;
      } else if (edgeFocused) {
        color = AppColors.accent.withValues(alpha: 0.6);
        width = 1.5;
      } else {
        color = AppColors.textSecondary.withValues(alpha: 0.18);
        width = 1;
      }

      canvas.drawLine(
        source.position,
        target.position,
        Paint()
          ..color = color
          ..strokeWidth = width,
      );
    }

    for (final node in nodes) {
      final isSelected = selectedNode?.id == node.id;
      final isHovered = hoveredNode?.id == node.id;
      final isActive = isSelected || isHovered;
      final isMatch = matchedNodeIds.contains(node.id);
      final dimmed = isDimmed(node.id) && !isActive;

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
          ..color = dimmed ? node.color.withValues(alpha: 0.12) : node.color
          ..style = PaintingStyle.fill,
      );

      // Viền: node chọn (accent), kết quả tìm kiếm (vàng), shop hoặc active.
      if (isSelected) {
        _strokeCircle(canvas, node, AppColors.accent, 2.5);
      } else if (isMatch && matchedNodeIds.isNotEmpty) {
        _strokeCircle(canvas, node, AppColors.orange, 2);
      } else if ((isActive || node.type == GraphNodeType.shop) && !dimmed) {
        _strokeCircle(
          canvas,
          node,
          Colors.white.withValues(alpha: 0.35),
          1.2,
        );
      }
    }

    // Nhãn tên cho shop khi bật "hiện tất cả nhãn" (giúp bao quát nhanh).
    if (showAllLabels) {
      for (final node in nodes) {
        if (node.type != GraphNodeType.shop) continue;
        if (node.id == hoveredNode?.id) continue;
        final dimmed = isDimmed(node.id);
        _drawCompactLabel(canvas, node, dimmed ? 0.35 : 1.0);
      }
    }

    // Tooltip giàu thông tin cho node đang hover (hoặc chọn).
    final tooltipNode = hoveredNode ?? selectedNode;
    if (tooltipNode != null) {
      _drawTooltip(canvas, tooltipNode, size);
    }
  }

  void _strokeCircle(Canvas canvas, GraphNode node, Color color, double width) {
    canvas.drawCircle(
      node.position,
      node.radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  void _drawCompactLabel(Canvas canvas, GraphNode node, double alpha) {
    final tp = TextPainter(
      text: TextSpan(
        text: node.label,
        style: TextStyle(
          color: AppColors.textPrimary.withValues(alpha: alpha),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 110);

    final dx = node.position.dx - tp.width / 2;
    final dy = node.position.dy + node.radius + 3;

    final bg = Paint()
      ..color = AppColors.background.withValues(alpha: 0.55 * alpha);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(dx - 3, dy - 1, tp.width + 6, tp.height + 2),
        const Radius.circular(4),
      ),
      bg,
    );
    tp.paint(canvas, Offset(dx, dy));
  }

  void _drawTooltip(Canvas canvas, GraphNode node, Size size) {
    final lines = <(String, String)>[];
    if (node.type == GraphNodeType.shop) {
      final neighborCount = edges
          .where((e) => e.sourceId == node.id || e.targetId == node.id)
          .length;
      lines.add(('Khu vực', node.locationGroup ?? 'Không rõ'));
      lines.add(('Loại', node.isOfficial ? 'Chính hãng' : 'Thường'));
      lines.add(('Sản phẩm', '$neighborCount'));
    } else if (node.product != null) {
      final p = node.product!;
      lines.add(('Giá', Formatters.priceFull(p.price)));
      lines.add(('Đã bán', Formatters.number(p.soldCount)));
      lines.add(('Rating', p.rating > 0 ? p.rating.toStringAsFixed(1) : '—'));
    }

    final titlePainter = TextPainter(
      text: TextSpan(
        text: node.label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: 220);

    final linePainters = lines.map((entry) {
      return TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${entry.$1}: ',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            TextSpan(
              text: entry.$2,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 220);
    }).toList();

    const padding = 10.0;
    const gap = 3.0;
    var contentWidth = titlePainter.width;
    for (final lp in linePainters) {
      contentWidth = math.max(contentWidth, lp.width);
    }
    var contentHeight = titlePainter.height;
    for (final lp in linePainters) {
      contentHeight += gap + lp.height;
    }

    final boxWidth = contentWidth + padding * 2;
    final boxHeight = contentHeight + padding * 2;

    // Đặt tooltip phía trên node, tự lật/kẹp để không tràn ra ngoài khung.
    var left = node.position.dx - boxWidth / 2;
    var top = node.position.dy - node.radius - boxHeight - 10;
    if (top < 4) {
      top = node.position.dy + node.radius + 10;
    }
    left = left.clamp(4.0, math.max(4.0, size.width - boxWidth - 4));

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, boxWidth, boxHeight),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = AppColors.card.withValues(alpha: 0.97),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    var y = top + padding;
    titlePainter.paint(canvas, Offset(left + padding, y));
    y += titlePainter.height + gap;
    for (final lp in linePainters) {
      lp.paint(canvas, Offset(left + padding, y));
      y += lp.height + gap;
    }
  }

  @override
  bool shouldRepaint(covariant BipartiteGraphPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.edges != edges ||
        oldDelegate.selectedNode != selectedNode ||
        oldDelegate.hoveredNode != hoveredNode ||
        oldDelegate.showAllLabels != showAllLabels ||
        oldDelegate.matchedNodeIds != matchedNodeIds;
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
