import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/models/graph_node.dart';
import 'package:shopee_app/providers/shop_product_graph_provider.dart';
import 'package:shopee_app/widgets/bipartite_graph_painter.dart';

class ShopProductGraphCanvas extends StatefulWidget {
  /// Khi giữ Ctrl và rê chuột trên graph, notifier này được bật `true` để màn
  /// hình khóa cuộn trang, đảm bảo lăn chuột chỉ zoom graph chứ không cuộn.
  final ValueNotifier<bool>? scrollLock;

  const ShopProductGraphCanvas({super.key, this.scrollLock});

  @override
  State<ShopProductGraphCanvas> createState() => _ShopProductGraphCanvasState();
}

class _ShopProductGraphCanvasState extends State<ShopProductGraphCanvas> {
  final TransformationController _transformController =
      TransformationController();
  Size? _lastLayoutSize;

  // Khi giữ Ctrl, lăn chuột sẽ zoom graph; nếu không, lăn chuột cuộn trang.
  bool _zoomEnabled = false;
  bool _isHovering = false;
  bool _showAllLabels = false;
  Size _viewportSize = Size.zero;
  int _nodeCount = 0;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    widget.scrollLock?.value = false;
    _transformController.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (isCtrl != _zoomEnabled) {
      setState(() => _zoomEnabled = isCtrl);
      _syncScrollLock();
    }
    return false;
  }

  void _setHovering(bool hovering) {
    if (hovering != _isHovering) {
      _isHovering = hovering;
      _syncScrollLock();
    }
  }

  void _syncScrollLock() {
    widget.scrollLock?.value = _zoomEnabled && _isHovering;
  }

  void _zoomBy(double factor) {
    if (_viewportSize == Size.zero) return;
    final focal = Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    final current = _transformController.value.getMaxScaleOnAxis();
    final minS = graphMinScale(_nodeCount);
    final maxS = graphMaxScale(_nodeCount);
    final target = (current * factor).clamp(minS, maxS);
    final applied = target / current;
    if ((applied - 1).abs() < 0.001) return;
    final m = Matrix4.copy(_transformController.value)
      ..translateByDouble(focal.dx, focal.dy, 0, 1)
      ..scaleByDouble(applied, applied, applied, 1)
      ..translateByDouble(-focal.dx, -focal.dy, 0, 1);
    _transformController.value = m;
  }

  void _fitToView(List<GraphNode> nodes) {
    if (nodes.isEmpty || _viewportSize == Size.zero) {
      _transformController.value = Matrix4.identity();
      return;
    }
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;
    for (final n in nodes) {
      minX = math.min(minX, n.position.dx - n.radius);
      minY = math.min(minY, n.position.dy - n.radius);
      maxX = math.max(maxX, n.position.dx + n.radius);
      maxY = math.max(maxY, n.position.dy + n.radius);
    }
    final bw = maxX - minX;
    final bh = maxY - minY;
    if (bw <= 0 || bh <= 0) {
      _transformController.value = Matrix4.identity();
      return;
    }
    const pad = 32.0;
    final scale = math
        .min(
          _viewportSize.width / (bw + pad * 2),
          _viewportSize.height / (bh + pad * 2),
        )
        .clamp(graphMinScale(_nodeCount), graphMaxScale(_nodeCount));
    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;
    final tx = _viewportSize.width / 2 - scale * cx;
    final ty = _viewportSize.height / 2 - scale * cy;
    _transformController.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
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
            _viewportSize = size;
            _nodeCount = provider.nodes.length;
            _maybeUpdateLayout(size, provider);

            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  InteractiveViewer(
                    transformationController: _transformController,
                    minScale: graphMinScale(provider.nodes.length),
                    maxScale: graphMaxScale(provider.nodes.length),
                    boundaryMargin: const EdgeInsets.all(120),
                    // Chỉ cho phép zoom bằng lăn chuột khi giữ Ctrl, tránh xung
                    // đột với việc cuộn trang. Kéo để di chuyển vẫn hoạt động.
                    scaleEnabled: _zoomEnabled,
                    child: MouseRegion(
                      onEnter: (_) => _setHovering(true),
                      onHover: (event) {
                        _setHovering(true);
                        final node = hitTestGraphNode(
                          event.localPosition,
                          provider.nodes,
                        );
                        provider.setHoveredNode(node);
                      },
                      onExit: (_) {
                        _setHovering(false);
                        provider.setHoveredNode(null);
                      },
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
                            showAllLabels: _showAllLabels,
                            matchedNodeIds: provider.matchedNodeIds,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 12,
                    bottom: 12,
                    child: _ZoomHint(),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Column(
                      children: [
                        _CanvasButton(
                          icon: Icons.add,
                          tooltip: 'Phóng to',
                          onTap: () => _zoomBy(1.25),
                        ),
                        const SizedBox(height: 8),
                        _CanvasButton(
                          icon: Icons.remove,
                          tooltip: 'Thu nhỏ',
                          onTap: () => _zoomBy(0.8),
                        ),
                        const SizedBox(height: 8),
                        _CanvasButton(
                          icon: Icons.fit_screen,
                          tooltip: 'Canh khít / Reset',
                          onTap: () => _fitToView(provider.nodes),
                        ),
                        const SizedBox(height: 8),
                        _CanvasButton(
                          icon: Icons.label_outline,
                          tooltip: _showAllLabels
                              ? 'Ẩn nhãn shop'
                              : 'Hiện nhãn shop',
                          active: _showAllLabels,
                          onTap: () => setState(
                            () => _showAllLabels = !_showAllLabels,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CanvasButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  const _CanvasButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active
            ? AppColors.accent.withValues(alpha: 0.9)
            : AppColors.card.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: AppColors.cardLight.withValues(alpha: 0.8),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 18,
              color: active ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomHint extends StatelessWidget {
  const _ZoomHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mouse, size: 14, color: AppColors.textSecondary),
          SizedBox(width: 6),
          Text(
            'Giữ Ctrl + lăn chuột để zoom · kéo để di chuyển',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class GraphLegend extends StatelessWidget {
  final GraphColorMode colorMode;

  const GraphLegend({super.key, required this.colorMode});

  @override
  Widget build(BuildContext context) {
    if (colorMode == GraphColorMode.official) {
      const items = [
        _LegendItem(color: AppColors.green, label: 'Shop chính hãng'),
        _LegendItem(color: AppColors.textSecondary, label: 'Shop thường'),
        _LegendItem(color: AppColors.blue, label: 'SP official'),
        _LegendItem(color: AppColors.cardLight, label: 'SP thường'),
      ];
      return Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          for (final item in items) _LegendRow(item: item),
          _sizeHint(),
        ],
      );
    }

    final locationPairs = [
      _LegendPair(
        shopColor: ShopProductGraphProvider.shopLocationColor('TP. Hồ Chí Minh'),
        productColor: ShopProductGraphProvider.productLocationColor('TP. Hồ Chí Minh'),
        label: 'TP. HCM',
      ),
      _LegendPair(
        shopColor: ShopProductGraphProvider.shopLocationColor('Hà Nội'),
        productColor: ShopProductGraphProvider.productLocationColor('Hà Nội'),
        label: 'Hà Nội',
      ),
      _LegendPair(
        shopColor: ShopProductGraphProvider.shopLocationColor('Tỉnh khác'),
        productColor: ShopProductGraphProvider.productLocationColor('Tỉnh khác'),
        label: 'Tỉnh khác',
      ),
      _LegendPair(
        shopColor: ShopProductGraphProvider.shopLocationColor('Không rõ'),
        productColor: ShopProductGraphProvider.productLocationColor('Không rõ'),
        label: 'Không rõ',
      ),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final pair in locationPairs) _LegendPairRow(pair: pair),
        _sizeHint(),
        const Text(
          '● Shop (đậm)  ○ SP (nhạt)',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _sizeHint() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: AppColors.textSecondary),
        SizedBox(width: 6),
        Text(
          'Node lớn = metric cao hơn',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final _LegendItem item;

  const _LegendRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

class _LegendPairRow extends StatelessWidget {
  final _LegendPair pair;

  const _LegendPairRow({required this.pair});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: pair.shopColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: pair.productColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          pair.label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
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

class _LegendPair {
  final Color shopColor;
  final Color productColor;
  final String label;

  const _LegendPair({
    required this.shopColor,
    required this.productColor,
    required this.label,
  });
}
