import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/core/utils/formatters.dart';
import 'package:shopee_app/models/graph_node.dart';
import 'package:shopee_app/models/product.dart';
import 'package:shopee_app/providers/shop_product_graph_provider.dart';
import 'package:shopee_app/widgets/shop_product_graph_canvas.dart';

class ShopProductGraphScreen extends StatefulWidget {
  const ShopProductGraphScreen({super.key});

  @override
  State<ShopProductGraphScreen> createState() => _ShopProductGraphScreenState();
}

class _ShopProductGraphScreenState extends State<ShopProductGraphScreen> {
  // Bật khi đang zoom graph (Ctrl + chuột trên graph) để khóa cuộn trang.
  final ValueNotifier<bool> _scrollLock = ValueNotifier(false);

  @override
  void dispose() {
    _scrollLock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopProductGraphProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.accent),
                SizedBox(height: 16),
                Text(
                  'Đang tải graph Shop ↔ Product...',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        if (provider.error != null) {
          return _ErrorState(
            message: provider.error!,
            onRetry: provider.loadData,
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = math.max(0.0, constraints.maxWidth - 48);
            final isCompact = contentWidth < 900;
            const minGraphHeight = 400.0;
            final graphHeight = math.max(
              minGraphHeight,
              constraints.maxHeight * 0.72,
            );

            return ValueListenableBuilder<bool>(
              valueListenable: _scrollLock,
              builder: (context, locked, child) {
                return SingleChildScrollView(
                  physics: locked
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  padding: const EdgeInsets.all(24),
                  child: child,
                );
              },
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(provider: provider, isCompact: isCompact),
                    const SizedBox(height: 12),
                    _GraphSearchBar(provider: provider),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: graphHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _GraphCanvasContainer(
                              scrollLock: _scrollLock,
                            ),
                          ),
                          Positioned(
                            left: 12,
                            top: 12,
                            child: IgnorePointer(
                              child: _GraphStatsOverlay(provider: provider),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FilterBar(provider: provider),
                    const SizedBox(height: 12),
                    GraphLegend(colorMode: provider.colorMode),
                    if (provider.selectedNode != null) ...[
                      const SizedBox(height: 16),
                      _NodeDetailPanel(
                        node: provider.selectedNode!,
                        edgeCount: provider.edges
                            .where(
                              (e) =>
                                  e.sourceId == provider.selectedNode!.id ||
                                  e.targetId == provider.selectedNode!.id,
                            )
                            .length,
                        shopSizeMetric: provider.shopSizeMetric,
                        shopProducts: provider.selectedNode!.type ==
                                    GraphNodeType.shop &&
                                provider.selectedNode!.shopId != null
                            ? provider.productsForShop(
                                provider.selectedNode!.shopId!,
                              )
                            : const [],
                        onClose: () => provider.selectNode(null),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _GraphCanvasContainer extends StatelessWidget {
  final ValueNotifier<bool>? scrollLock;

  const _GraphCanvasContainer({this.scrollLock});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cardLight.withValues(alpha: 0.5),
        ),
      ),
      child: ShopProductGraphCanvas(scrollLock: scrollLock),
    );
  }
}

class _Header extends StatelessWidget {
  final ShopProductGraphProvider provider;
  final bool isCompact;

  const _Header({required this.provider, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final titleSection = const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Network Graph — Shop ↔ Product',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Bipartite graph: shop ở trung tâm (hub), sản phẩm xung quanh. Kéo/zoom để khám phá.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: provider.loadData,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Làm mới'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: BorderSide(color: AppColors.cardLight.withValues(alpha: 0.8)),
          ),
        ),
        if (provider.lastUpdated != null)
          Text(
            'Cập nhật: ${Formatters.date(provider.lastUpdated)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleSection,
          const SizedBox(height: 12),
          actions,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: titleSection),
        actions,
      ],
    );
  }
}

class _GraphSearchBar extends StatelessWidget {
  final ShopProductGraphProvider provider;

  const _GraphSearchBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 320,
          height: 38,
          child: TextField(
            onChanged: provider.setSearchQuery,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: 'Tìm shop hoặc sản phẩm trên graph...',
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.card,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (provider.searchQuery.isNotEmpty) ...[
          const SizedBox(width: 12),
          Icon(
            provider.matchCount > 0 ? Icons.bolt : Icons.search_off,
            size: 16,
            color: provider.matchCount > 0
                ? AppColors.orange
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            provider.matchCount > 0
                ? '${provider.matchCount} kết quả được tô sáng'
                : 'Không có kết quả khớp',
            style: TextStyle(
              color: provider.matchCount > 0
                  ? AppColors.orange
                  : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _GraphStatsOverlay extends StatelessWidget {
  final ShopProductGraphProvider provider;

  const _GraphStatsOverlay({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardLight.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatItem(
            icon: Icons.store,
            color: AppColors.green,
            value: Formatters.number(provider.shopNodeCount),
            label: 'shop',
          ),
          _statDivider(),
          _StatItem(
            icon: Icons.inventory_2,
            color: AppColors.blue,
            value: Formatters.number(provider.productNodeCount),
            label: 'SP',
          ),
          _statDivider(),
          _StatItem(
            icon: Icons.hub,
            color: AppColors.accentLight,
            value: Formatters.number(provider.edges.length),
            label: 'liên kết',
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.cardLight.withValues(alpha: 0.7),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final ShopProductGraphProvider provider;

  const _FilterBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Dropdown<String?>(
            label: 'Khu vực',
            value: provider.selectedLocation,
            items: [
              const DropdownMenuItem(value: null, child: Text('Tất cả')),
              ...provider.locationOptions.map(
                (loc) => DropdownMenuItem(value: loc, child: Text(loc)),
              ),
            ],
            onChanged: provider.setLocationFilter,
          ),
          _Dropdown<GraphColorMode>(
            label: 'Màu node',
            value: provider.colorMode,
            items: const [
              DropdownMenuItem(
                value: GraphColorMode.official,
                child: Text('Official / Thường'),
              ),
              DropdownMenuItem(
                value: GraphColorMode.location,
                child: Text('Theo khu vực'),
              ),
            ],
            onChanged: (v) {
              if (v != null) provider.setColorMode(v);
            },
          ),
          _Dropdown<GraphShopSizeMetric>(
            label: 'Size Shop',
            value: provider.shopSizeMetric,
            items: const [
              DropdownMenuItem(
                value: GraphShopSizeMetric.totalSold,
                child: Text('Tổng sold'),
              ),
              DropdownMenuItem(
                value: GraphShopSizeMetric.revenue,
                child: Text('Doanh thu ước tính'),
              ),
            ],
            onChanged: (v) {
              if (v != null) provider.setShopSizeMetric(v);
            },
          ),
          _Dropdown<GraphProductSizeMetric>(
            label: 'Size SP',
            value: provider.productSizeMetric,
            items: const [
              DropdownMenuItem(
                value: GraphProductSizeMetric.monthlySold,
                child: Text('Bán tháng'),
              ),
              DropdownMenuItem(
                value: GraphProductSizeMetric.rating,
                child: Text('Rating'),
              ),
            ],
            onChanged: (v) {
              if (v != null) provider.setProductSizeMetric(v);
            },
          ),
          _Dropdown<int?>(
            label: 'Hiển thị',
            value: provider.topN,
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả SP')),
              DropdownMenuItem(value: 25, child: Text('Top 25')),
              DropdownMenuItem(value: 50, child: Text('Top 50')),
              DropdownMenuItem(value: 100, child: Text('Top 100')),
            ],
            onChanged: provider.setTopN,
          ),
          FilterChip(
            label: const Text('Chỉ shop chính hãng'),
            selected: provider.officialOnly,
            onSelected: provider.setOfficialOnly,
            selectedColor: AppColors.accent.withValues(alpha: 0.25),
            checkmarkColor: AppColors.accent,
            labelStyle: TextStyle(
              color: provider.officialOnly
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(width: 6),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              dropdownColor: AppColors.card,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _NodeDetailPanel extends StatelessWidget {
  final GraphNode node;
  final int edgeCount;
  final GraphShopSizeMetric shopSizeMetric;
  final VoidCallback onClose;
  final List<Product> shopProducts;

  const _NodeDetailPanel({
    required this.node,
    required this.edgeCount,
    required this.shopSizeMetric,
    required this.onClose,
    this.shopProducts = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardLight.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: node.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.type == GraphNodeType.shop ? 'Shop Node' : 'Product Node',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            node.label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (node.type == GraphNodeType.shop) ...[
            _DetailRow(
              label: 'Shop ID',
              value: node.shopId?.toString() ?? '-',
            ),
            _DetailRow(
              label: 'Khu vực',
              value: node.locationGroup ?? 'Không rõ',
            ),
            _DetailRow(
              label: 'Loại',
              value: node.isOfficial ? 'Chính hãng' : 'Thường',
            ),
            _DetailRow(
              label: 'Metric (size)',
              value: shopSizeMetric == GraphShopSizeMetric.revenue
                  ? Formatters.priceFull(node.metricValue)
                  : Formatters.number(node.metricValue.toInt()),
            ),
            _DetailRow(
              label: 'Kết nối',
              value: '$edgeCount sản phẩm',
            ),
            if (shopProducts.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'SẢN PHẨM CỦA SHOP',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: shopProducts.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 12,
                    color: AppColors.cardLight.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, i) =>
                      _ShopProductRow(product: shopProducts[i]),
                ),
              ),
            ],
          ] else if (node.product != null) ...[
            _DetailRow(
              label: 'Giá',
              value: Formatters.priceFull(node.product!.price),
            ),
            _DetailRow(
              label: 'Rating',
              value: node.product!.rating.toStringAsFixed(1),
            ),
            _DetailRow(
              label: 'Bán tháng',
              value: Formatters.number(node.product!.monthlySoldCount),
            ),
            _DetailRow(
              label: 'Tổng sold',
              value: Formatters.number(node.product!.soldCount),
            ),
            _DetailRow(
              label: 'Shop ID',
              value: node.product!.shopId.toString(),
            ),
            if (node.product!.isOfficialShop)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Chip(
                  label: Text(
                    'Official Shop',
                    style: TextStyle(fontSize: 11),
                  ),
                  backgroundColor: AppColors.green,
                  labelStyle: TextStyle(color: Colors.white),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopProductRow extends StatelessWidget {
  final Product product;

  const _ShopProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    Formatters.priceFull(product.price),
                    style: const TextStyle(
                      color: AppColors.accentLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.star,
                    size: 11,
                    color: AppColors.orange.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    product.rating > 0
                        ? product.rating.toStringAsFixed(1)
                        : '—',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Đã bán\n${Formatters.number(product.soldCount)}',
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.accent, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
