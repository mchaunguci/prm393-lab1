import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/core/utils/formatters.dart';
import 'package:shopee_app/providers/price_compare_provider.dart';
import 'package:shopee_app/screens/price_compare/product_table_row.dart';
import 'package:shopee_app/screens/price_compare/shared.dart';

class ProductTableCard extends StatelessWidget {
  final PriceCompareProvider provider;
  final double width;

  const ProductTableCard({
    super.key,
    required this.provider,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final allProducts = provider.filteredProducts;
    final pageProducts = provider.pagedProducts;

    final activeFilterCount = [
      provider.filter.minRating != null,
      provider.filter.canUseCod == true,
    ].where((v) => v).length;

    return Container(
      width: width,
      decoration: cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Danh sách chi tiết sản phẩm',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${Formatters.number(allProducts.length)} sản phẩm',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _FilterButton(
                      provider: provider,
                      activeCount: activeFilterCount,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tính năng đang phát triển'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: const Text(
                        'Xuất Excel',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.cardLight),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.cardLight, height: 1),
          if (allProducts.isEmpty)
            const SizedBox(
              height: 180,
              child: EmptyMessage(message: 'Không tìm thấy sản phẩm phù hợp.'),
            )
          else
            Column(
              children: [
                const ProductTableHeader(),
                const Divider(color: AppColors.cardLight, height: 1),
                ...pageProducts.map(
                  (p) => ProductTableRow(
                    product: p,
                    shopName: provider.shopNameFor(p.shopId),
                  ),
                ),
                _PaginationBar(
                  provider: provider,
                  totalCount: allProducts.length,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final PriceCompareProvider provider;
  final int activeCount;

  const _FilterButton({required this.provider, required this.activeCount});

  @override
  Widget build(BuildContext context) {
    final f = provider.filter;

    return PopupMenuButton<String>(
      tooltip: 'Bộ lọc',
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.card,
      onSelected: (value) {
        provider.clearFilter();

        switch (value) {
          case 'all':
            break;

          case 'rating_45':
            provider.setFilter(
              provider.filter.copyWith(minRating: 4.5),
            );
            break;

          case 'rating_40':
            provider.setFilter(
              provider.filter.copyWith(minRating: 4.0),
            );
            break;

          case 'cod':
            provider.setFilter(provider.filter.copyWith(canUseCod: true));
            break;
        }
      },
      itemBuilder: (context) => [
        _menuItem(
          value: 'all',
          label: 'Tất cả',
          icon: Icons.apps,
          active: !f.isAnyActive,
        ),
        _menuItem(
          value: 'rating_45',
          label: 'Đánh giá ≥ 4.5',
          icon: Icons.star,
          active: f.minRating == 4.5,
        ),
        _menuItem(
          value: 'rating_40',
          label: 'Đánh giá ≥ 4.0',
          icon: Icons.star_half,
          active: f.minRating == 4.0,
        ),
        _menuItem(
          value: 'cod',
          label: 'Hỗ trợ COD',
          icon: Icons.payments,
          active: f.canUseCod == true,
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list, size: 16),
            SizedBox(width: 6),
            Text('Bộ lọc', style: TextStyle(fontSize: 12)),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem({
    required String value,
    required String label,
    required IconData icon,
    required bool active,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: active ? AppColors.accent : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: active ? AppColors.accent : AppColors.textPrimary,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          if (active)
            const Icon(Icons.check, size: 16, color: AppColors.accent),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final PriceCompareProvider provider;
  final int totalCount;

  const _PaginationBar({required this.provider, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    final totalPages = provider.totalPages;
    final current = provider.currentPage;

    if (totalCount == 0 || totalPages == 0) {
      return const SizedBox.shrink();
    }

    final start = current * PriceCompareProvider.pageSize + 1;
    final end = ((current + 1) * PriceCompareProvider.pageSize).clamp(
      0,
      totalCount,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Hiển thị $start–$end / $totalCount',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          Row(
            children: [
              _PageIconButton(
                icon: Icons.chevron_left,
                enabled: current > 0,
                onTap: () => provider.setPage(current - 1),
              ),
              const SizedBox(width: 4),
              ..._buildPageNumbers(current, totalPages),
              const SizedBox(width: 4),
              _PageIconButton(
                icon: Icons.chevron_right,
                enabled: current < totalPages - 1,
                onTap: () => provider.setPage(current + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(int current, int totalPages) {
    final pages = <int>{0, totalPages - 1, current};

    for (int delta = -1; delta <= 1; delta++) {
      final p = current + delta;
      if (p >= 0 && p < totalPages) {
        pages.add(p);
      }
    }

    final sorted = pages.toList()..sort();
    final widgets = <Widget>[];

    int? prev;

    for (final p in sorted) {
      if (prev != null && p - prev > 1) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '…',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        );
      }

      widgets.add(
        _PageNumberChip(
          page: p,
          isActive: p == current,
          onTap: () => provider.setPage(p),
        ),
      );

      prev = p;
    }

    return widgets;
  }
}

class _PageNumberChip extends StatelessWidget {
  final int page;
  final bool isActive;
  final VoidCallback onTap;

  const _PageNumberChip({
    required this.page,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: isActive ? null : onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : Colors.transparent,
            border: Border.all(
              color: isActive ? AppColors.accent : AppColors.cardLight,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            '${page + 1}',
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.textPrimary,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _PageIconButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageIconButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardLight),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
