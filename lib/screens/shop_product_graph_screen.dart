import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/core/utils/formatters.dart';
import 'package:shopee_app/models/graph_node.dart';
import 'package:shopee_app/providers/shop_product_graph_provider.dart';
import 'package:shopee_app/widgets/shop_product_graph_canvas.dart';
import 'package:shopee_app/widgets/stat_card.dart';

class ShopProductGraphScreen extends StatelessWidget {
  const ShopProductGraphScreen({super.key});

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

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(provider: provider),
              const SizedBox(height: 16),
              _SummaryRow(provider: provider),
              const SizedBox(height: 16),
              _FilterBar(provider: provider),
              const SizedBox(height: 12),
              GraphLegend(colorMode: provider.colorMode),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: provider.selectedNode != null ? 3 : 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.cardLight.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const ShopProductGraphCanvas(),
                      ),
                    ),
                    if (provider.selectedNode != null) ...[
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 320,
                        child: _NodeDetailPanel(
                          node: provider.selectedNode!,
                          edgeCount: provider.edges
                              .where(
                                (e) =>
                                    e.sourceId == provider.selectedNode!.id ||
                                    e.targetId == provider.selectedNode!.id,
                              )
                              .length,
                          shopSizeMetric: provider.shopSizeMetric,
                          onClose: () => provider.selectNode(null),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final ShopProductGraphProvider provider;

  const _Header({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
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
          ),
        ),
        OutlinedButton.icon(
          onPressed: provider.loadData,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Làm mới'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: BorderSide(color: AppColors.cardLight.withValues(alpha: 0.8)),
          ),
        ),
        if (provider.lastUpdated != null) ...[
          const SizedBox(width: 12),
          Text(
            'Cập nhật: ${Formatters.date(provider.lastUpdated)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final ShopProductGraphProvider provider;

  const _SummaryRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        StatCard(
          title: 'Shop nodes',
          value: Formatters.number(provider.shopNodeCount),
          icon: Icons.store,
        ),
        StatCard(
          title: 'Product nodes',
          value: Formatters.number(provider.productNodeCount),
          icon: Icons.inventory_2,
        ),
        StatCard(
          title: 'Edges',
          value: Formatters.number(provider.edges.length),
          icon: Icons.hub,
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
          SizedBox(
            width: 220,
            height: 36,
            child: TextField(
              onChanged: provider.setSearchQuery,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tìm shop hoặc sản phẩm...',
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
                fillColor: AppColors.surface,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
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

  const _NodeDetailPanel({
    required this.node,
    required this.edgeCount,
    required this.shopSizeMetric,
    required this.onClose,
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
