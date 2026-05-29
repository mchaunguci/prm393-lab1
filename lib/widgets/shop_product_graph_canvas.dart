import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/models/graph_node.dart';
import 'package:shopee_app/providers/shop_product_graph_provider.dart';
import 'package:shopee_app/widgets/bipartite_graph_painter.dart';

class ShopProductGraphCanvas extends StatefulWidget {
  const ShopProductGraphCanvas({super.key});

  @override
  State<ShopProductGraphCanvas> createState() => _ShopProductGraphCanvasState();
}

class _ShopProductGraphCanvasState extends State<ShopProductGraphCanvas> {
  final TransformationController _transformController = TransformationController();
  Size? _lastLayoutSize;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _maybeUpdateLayout(Size size, ShopProductGraphProvider provider) {
    if (size.width < 48 || size.height < 48) return;

    final previous = _lastLayoutSize;
    if (previous != null &&
        (previous.width - size.width).abs() <= 8 &&
        (previous.height - size.height).abs() <= 8) {
      return;
    }

    _lastLayoutSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      provider.updateLayout(size);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopProductGraphProvider>(
      builder: (context, provider, _) {
        if (provider.nodes.isEmpty) {
          return const Center(
            child: Text(
              'Không có dữ liệu graph phù hợp bộ lọc',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            _maybeUpdateLayout(size, provider);

            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: graphMinScale(provider.nodes.length),
                maxScale: graphMaxScale(provider.nodes.length),
                boundaryMargin: const EdgeInsets.all(120),
                child: MouseRegion(
                  onHover: (event) {
                    final node = hitTestGraphNode(
                      event.localPosition,
                      provider.nodes,
                    );
                    provider.setHoveredNode(node);
                  },
                  onExit: (_) => provider.setHoveredNode(null),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      final node = hitTestGraphNode(
                        details.localPosition,
                        provider.nodes,
                      );
                      provider.selectNode(
                        provider.selectedNode?.id == node?.id ? null : node,
                      );
                    },
                    child: CustomPaint(
                      size: size,
                      painter: BipartiteGraphPainter(
                        nodes: provider.nodes,
                        edges: provider.edges,
                        selectedNode: provider.selectedNode,
                        hoveredNode: provider.hoveredNode,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class GraphLegend extends StatelessWidget {
  final GraphColorMode colorMode;

  const GraphLegend({super.key, required this.colorMode});

  @override
  Widget build(BuildContext context) {
    final items = colorMode == GraphColorMode.official
        ? const [
            _LegendItem(color: AppColors.green, label: 'Shop chính hãng'),
            _LegendItem(color: AppColors.textSecondary, label: 'Shop thường'),
            _LegendItem(color: AppColors.blue, label: 'SP official'),
            _LegendItem(color: AppColors.cardLight, label: 'SP thường'),
          ]
        : const [
            _LegendItem(color: AppColors.blue, label: 'TP. HCM'),
            _LegendItem(color: AppColors.orange, label: 'Hà Nội'),
            _LegendItem(color: AppColors.purple, label: 'Tỉnh khác'),
            _LegendItem(color: AppColors.textSecondary, label: 'Không rõ'),
          ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 10, color: AppColors.textSecondary),
            SizedBox(width: 6),
            Text(
              'Node lớn = metric cao hơn',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});
}
