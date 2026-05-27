import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/core/utils/formatters.dart';
import 'package:shopee_app/models/product.dart';
import 'package:shopee_app/models/shop_analytics_item.dart';
import 'package:shopee_app/providers/shop_analysis_provider.dart';
import 'package:shopee_app/widgets/stat_card.dart';

class ShopAnalysisScreen extends StatelessWidget {
  const ShopAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopAnalysisProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.accent),
                SizedBox(height: 16),
                Text(
                  'Đang tải dữ liệu shop...',
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(provider: provider, width: contentWidth),
                    const SizedBox(height: 24),
                    _SummaryCards(provider: provider, width: contentWidth),
                    const SizedBox(height: 16),
                    _FilterBar(provider: provider, width: contentWidth),
                    const SizedBox(height: 24),
                    _AnalyticsCards(provider: provider, width: contentWidth),
                    const SizedBox(height: 24),
                    _ShopRankingTable(
                      shops: provider.shopStats,
                      pagedShops: provider.pagedShopStats,
                      width: contentWidth,
                      currentPage: provider.currentPage,
                      totalPages: provider.totalShopPages,
                      visibleStart: provider.visibleShopStart,
                      visibleEnd: provider.visibleShopEnd,
                      canGoPrevious: provider.canGoToPreviousShopPage,
                      canGoNext: provider.canGoToNextShopPage,
                      onPreviousPage: provider.previousShopPage,
                      onNextPage: provider.nextShopPage,
                      onShopTap: (shop) =>
                          _openShopDetail(context, provider, shop),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openShopDetail(
    BuildContext context,
    ShopAnalysisProvider provider,
    ShopAnalyticsItem shop,
  ) async {
    provider.selectShop(shop);
    await showDialog<void>(
      context: context,
      builder: (_) => _ShopDetailDialog(shop: shop),
    );
    if (context.mounted) {
      provider.clearSelectedShop();
    }
  }
}

class _Header extends StatelessWidget {
  final ShopAnalysisProvider provider;
  final double width;

  const _Header({required this.provider, required this.width});

  @override
  Widget build(BuildContext context) {
    final buttonWidth = width < 460 ? width : 132.0;
    final titleWidth = width < 460
        ? width
        : math.max(0.0, width - buttonWidth - 16);

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: titleWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phân tích Shop',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Phân tích hiệu suất theo từng shop/người bán',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.72),
                  fontSize: 13,
                ),
              ),
              if (provider.lastUpdated != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Dữ liệu cập nhật: ${Formatters.date(provider.lastUpdated)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          width: buttonWidth,
          height: 42,
          child: ElevatedButton.icon(
            onPressed: provider.loadData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Làm mới'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final ShopAnalysisProvider provider;
  final double width;

  const _SummaryCards({required this.provider, required this.width});

  @override
  Widget build(BuildContext context) {
    final cardWidth = width < 760 ? width : (width - 32) / 3;

    final cards = [
      StatCard(
        title: 'TỔNG SỐ SHOP',
        value: Formatters.number(provider.totalShops),
        subtitle: '${Formatters.number(provider.totalProducts)} sản phẩm',
        icon: Icons.storefront,
      ),
      StatCard(
        title: 'SHOP CHÍNH HÃNG',
        value: Formatters.number(provider.officialShopCount),
        subtitle: 'shop có nhãn official',
        icon: Icons.verified,
      ),
      StatCard(
        title: 'KHU VỰC NHIỀU SHOP NHẤT',
        value: provider.topLocation,
        subtitle: 'theo phân bổ hiện tại',
        icon: Icons.map_outlined,
      ),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: cards
          .map((card) => SizedBox(width: math.max(0.0, cardWidth), child: card))
          .toList(),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final ShopAnalysisProvider provider;
  final double width;

  const _FilterBar({required this.provider, required this.width});

  @override
  Widget build(BuildContext context) {
    final innerWidth = math.max(0.0, width - 32);
    final isStacked = innerWidth < 820;
    final searchWidth = isStacked ? innerWidth : innerWidth - 190 - 230 - 24;
    final locationWidth = isStacked ? innerWidth : 190.0;
    final sortWidth = isStacked ? innerWidth : 230.0;

    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: math.max(0.0, searchWidth),
            child: _SearchField(provider: provider),
          ),
          SizedBox(
            width: math.max(0.0, locationWidth),
            child: _LocationFilter(provider: provider, width: locationWidth),
          ),
          SizedBox(
            width: math.max(0.0, sortWidth),
            child: _SortFilter(provider: provider, width: sortWidth),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ShopAnalysisProvider provider;

  const _SearchField({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        onChanged: provider.searchShop,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Tìm theo tên shop...',
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: 18,
          ),
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.cardLight),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.accent),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _LocationFilter extends StatelessWidget {
  final ShopAnalysisProvider provider;
  final double width;

  const _LocationFilter({required this.provider, required this.width});

  @override
  Widget build(BuildContext context) {
    return _FilterButton(
      width: width,
      label: provider.selectedLocation ?? 'Tất cả khu vực',
      onSelected: (value) =>
          provider.filterByLocation(value == '' ? null : value),
      items: [
        const PopupMenuItem(value: '', child: Text('Tất cả khu vực')),
        ...provider.locationOptions.map(
          (location) => PopupMenuItem(value: location, child: Text(location)),
        ),
      ],
    );
  }
}

class _SortFilter extends StatelessWidget {
  final ShopAnalysisProvider provider;
  final double width;

  const _SortFilter({required this.provider, required this.width});

  @override
  Widget build(BuildContext context) {
    return _FilterButton(
      width: width,
      label: provider.sortOption.label,
      onSelected: (value) => provider.sortBy(value),
      items: ShopSortOption.values
          .map(
            (option) => PopupMenuItem(value: option, child: Text(option.label)),
          )
          .toList(),
    );
  }
}

class _FilterButton<T> extends StatelessWidget {
  final double width;
  final String label;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T> onSelected;

  const _FilterButton({
    required this.width,
    required this.label,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      color: AppColors.card,
      onSelected: onSelected,
      itemBuilder: (_) => items,
      child: Container(
        height: 42,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.cardLight),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: math.max(0.0, width - 52),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.expand_more,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsCards extends StatelessWidget {
  final ShopAnalysisProvider provider;
  final double width;

  const _AnalyticsCards({required this.provider, required this.width});

  @override
  Widget build(BuildContext context) {
    if (width < 920) {
      return Column(
        children: [
          SizedBox(
            width: width,
            height: 320,
            child: _TopProductsCard(shops: provider.topByProductCount),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: width,
            height: 320,
            child: _LocationDistributionCard(
              data: provider.locationDistribution,
            ),
          ),
        ],
      );
    }

    final chartWidth = (width - 16) * 0.6;
    final locationWidth = (width - 16) * 0.4;

    return Row(
      children: [
        SizedBox(
          width: chartWidth,
          height: 320,
          child: _TopProductsCard(shops: provider.topByProductCount),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: locationWidth,
          height: 320,
          child: _LocationDistributionCard(data: provider.locationDistribution),
        ),
      ],
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  final List<ShopAnalyticsItem> shops;

  const _TopProductsCard({required this.shops});

  @override
  Widget build(BuildContext context) {
    final maxProducts = shops.isEmpty
        ? 0
        : shops
              .map((shop) => shop.productCount)
              .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 5 shop theo số sản phẩm',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 230,
            child: shops.isEmpty
                ? const _EmptyMessage(message: 'Không có dữ liệu shop')
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: shops.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final shop = shops[index];
                      final ratio = maxProducts == 0
                          ? 0.0
                          : shop.productCount / maxProducts;
                      return _ProgressMetricRow(
                        label: shop.shopName,
                        value: '${Formatters.number(shop.productCount)} SP',
                        ratio: ratio,
                        color: AppColors
                            .chartColors[index % AppColors.chartColors.length],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LocationDistributionCard extends StatelessWidget {
  final Map<String, int> data;

  const _LocationDistributionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<int>(0, (sum, value) => sum + value);
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân bổ shop theo khu vực',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 230,
            child: entries.isEmpty
                ? const _EmptyMessage(message: 'Không có dữ liệu khu vực')
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final value = entry.value;
                      final ratio = total == 0 ? 0.0 : value / total;
                      return _ProgressMetricRow(
                        label: entry.key,
                        value: '${(ratio * 100).toStringAsFixed(0)}%',
                        ratio: ratio,
                        color: AppColors
                            .chartColors[index % AppColors.chartColors.length],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProgressMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final double ratio;
  final Color color;

  const _ProgressMetricRow({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio.clamp(0, 1),
            minHeight: 8,
            backgroundColor: AppColors.cardLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _ShopRankingTable extends StatelessWidget {
  final List<ShopAnalyticsItem> shops;
  final List<ShopAnalyticsItem> pagedShops;
  final double width;
  final int currentPage;
  final int totalPages;
  final int visibleStart;
  final int visibleEnd;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final ValueChanged<ShopAnalyticsItem> onShopTap;

  const _ShopRankingTable({
    required this.shops,
    required this.pagedShops,
    required this.width,
    required this.currentPage,
    required this.totalPages,
    required this.visibleStart,
    required this.visibleEnd,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onShopTap,
  });

  @override
  Widget build(BuildContext context) {
    final tableWidth = math.max(width, 1040.0);
    final columns = _ShopTableColumns.forWidth(tableWidth - 32);

    return Container(
      width: width,
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Danh sách Shop',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${Formatters.number(shops.length)} shop',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.cardLight, height: 1),
          if (shops.isEmpty)
            const SizedBox(
              height: 180,
              child: _EmptyMessage(
                message: 'Không tìm thấy shop phù hợp với bộ lọc hiện tại.',
              ),
            )
          else
            Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        _ShopTableHeader(columns: columns),
                        const Divider(color: AppColors.cardLight, height: 1),
                        ...pagedShops.map(
                          (shop) => _ShopTableRow(
                            shop: shop,
                            columns: columns,
                            onTap: () => onShopTap(shop),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(color: AppColors.cardLight, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: math.max(0.0, math.min(260.0, width - 32)),
                        child: Text(
                          'Hiển thị $visibleStart-$visibleEnd / ${Formatters.number(shops.length)} shop',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _TablePaginationControls(
                        currentPage: currentPage,
                        totalPages: totalPages,
                        canGoPrevious: canGoPrevious,
                        canGoNext: canGoNext,
                        onPreviousPage: onPreviousPage,
                        onNextPage: onNextPage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TablePaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  const _TablePaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PaginationButton(
          label: 'Previous',
          onPressed: canGoPrevious ? onPreviousPage : null,
        ),
        const SizedBox(width: 10),
        Text(
          'Trang $currentPage / $totalPages',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        _PaginationButton(
          label: 'Next',
          onPressed: canGoNext ? onNextPage : null,
        ),
      ],
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _PaginationButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.textSecondary.withValues(
            alpha: 0.45,
          ),
          side: const BorderSide(color: AppColors.cardLight),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _ShopTableColumns {
  final double shopName;
  final double location;
  final double productCount;
  final double totalSold;
  final double monthlySold;
  final double rating;
  final double averagePrice;
  final double revenue;
  final double official;

  const _ShopTableColumns({
    required this.shopName,
    required this.location,
    required this.productCount,
    required this.totalSold,
    required this.monthlySold,
    required this.rating,
    required this.averagePrice,
    required this.revenue,
    required this.official,
  });

  factory _ShopTableColumns.forWidth(double width) {
    final safeWidth = math.max(width, 1008.0);
    final shopName = safeWidth * 0.27;
    final location = safeWidth * 0.15;
    final productCount = safeWidth * 0.075;
    final totalSold = safeWidth * 0.105;
    final monthlySold = safeWidth * 0.095;
    final rating = safeWidth * 0.07;
    final averagePrice = safeWidth * 0.10;
    final official = safeWidth * 0.065;
    final usedWidth =
        shopName +
        location +
        productCount +
        totalSold +
        monthlySold +
        rating +
        averagePrice +
        official;

    return _ShopTableColumns(
      shopName: shopName,
      location: location,
      productCount: productCount,
      totalSold: totalSold,
      monthlySold: monthlySold,
      rating: rating,
      averagePrice: averagePrice,
      revenue: safeWidth - usedWidth,
      official: official,
    );
  }
}

class _ShopTableHeader extends StatelessWidget {
  final _ShopTableColumns columns;

  const _ShopTableHeader({required this.columns});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardLight.withValues(alpha: 0.55),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _TableCell(
            width: columns.shopName,
            text: 'SHOP NAME',
            isHeader: true,
          ),
          _TableCell(width: columns.location, text: 'KHU VỰC', isHeader: true),
          _TableCell(
            width: columns.productCount,
            text: 'SỐ SP',
            isHeader: true,
            alignRight: true,
          ),
          _TableCell(
            width: columns.totalSold,
            text: 'TỔNG ĐÃ BÁN',
            isHeader: true,
            alignRight: true,
          ),
          _TableCell(
            width: columns.monthlySold,
            text: 'BÁN/THÁNG',
            isHeader: true,
            alignRight: true,
          ),
          _TableCell(
            width: columns.rating,
            text: 'RATING',
            isHeader: true,
            alignRight: true,
          ),
          _TableCell(
            width: columns.averagePrice,
            text: 'GIÁ TB',
            isHeader: true,
            alignRight: true,
          ),
          _TableCell(
            width: columns.revenue,
            text: 'DOANH THU ƯỚC TÍNH',
            isHeader: true,
            alignRight: true,
          ),
          _TableCell(
            width: columns.official,
            text: 'OFFICIAL',
            isHeader: true,
            alignRight: true,
          ),
        ],
      ),
    );
  }
}

class _ShopTableRow extends StatelessWidget {
  final ShopAnalyticsItem shop;
  final _ShopTableColumns columns;
  final VoidCallback onTap;

  const _ShopTableRow({
    required this.shop,
    required this.columns,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.cardLight.withValues(alpha: 0.35),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.cardLight, width: 0.7),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: columns.shopName,
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.cardLight),
                      ),
                      child: Icon(
                        shop.isOfficial ? Icons.verified : Icons.storefront,
                        color: shop.isOfficial
                            ? AppColors.blue
                            : AppColors.textSecondary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        shop.shopName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              _TableCell(width: columns.location, text: shop.location),
              _TableCell(
                width: columns.productCount,
                text: Formatters.number(shop.productCount),
                alignRight: true,
                isNumber: true,
              ),
              _TableCell(
                width: columns.totalSold,
                text: Formatters.number(shop.totalSold),
                alignRight: true,
                isNumber: true,
              ),
              _TableCell(
                width: columns.monthlySold,
                text: Formatters.number(shop.monthlySold),
                alignRight: true,
                isNumber: true,
              ),
              _TableCell(
                width: columns.rating,
                text: shop.averageRating.toStringAsFixed(1),
                alignRight: true,
                isNumber: true,
              ),
              _TableCell(
                width: columns.averagePrice,
                text: Formatters.priceShort(shop.averagePrice),
                alignRight: true,
                isNumber: true,
              ),
              _TableCell(
                width: columns.revenue,
                text: Formatters.priceShort(shop.totalRevenueEstimate),
                alignRight: true,
                isNumber: true,
              ),
              SizedBox(
                width: columns.official,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _OfficialBadge(isOfficial: shop.isOfficial),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final double width;
  final String text;
  final bool isHeader;
  final bool alignRight;
  final bool isNumber;

  const _TableCell({
    required this.width,
    required this.text,
    this.isHeader = false,
    this.alignRight = false,
    this.isNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          color: isHeader ? AppColors.textSecondary : AppColors.textPrimary,
          fontSize: isHeader ? 11 : 12,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: isHeader ? 0.6 : 0,
          fontFamily: isNumber ? 'JetBrains Mono' : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _OfficialBadge extends StatelessWidget {
  final bool isOfficial;

  const _OfficialBadge({required this.isOfficial});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isOfficial ? AppColors.blue : AppColors.cardLight).withValues(
          alpha: isOfficial ? 0.16 : 0.8,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isOfficial ? AppColors.blue : AppColors.cardLight,
        ),
      ),
      child: Text(
        isOfficial ? 'Có' : 'Không',
        style: TextStyle(
          color: isOfficial ? AppColors.blue : AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ShopDetailDialog extends StatelessWidget {
  final ShopAnalyticsItem shop;

  const _ShopDetailDialog({required this.shop});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(940.0, math.max(360.0, screenSize.width - 64));
    final productListHeight = math.min(
      320.0,
      math.max(180.0, screenSize.height - 360),
    );
    final productRowsHeight = math.max(96.0, productListHeight - 78);
    final titleWidth = math.max(0.0, dialogWidth - 88);

    return Dialog(
      backgroundColor: AppColors.card,
      insetPadding: const EdgeInsets.all(32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: titleWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: math.max(
                                0.0,
                                titleWidth - (shop.isOfficial ? 28 : 0),
                              ),
                              child: Text(
                                shop.shopName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (shop.isOfficial) ...[
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.verified,
                                color: AppColors.blue,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${shop.location} • ${Formatters.number(shop.productCount)} sản phẩm',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'Đóng',
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.cardLight, height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _DetailStat(
                    label: 'SỐ SẢN PHẨM',
                    value: Formatters.number(shop.productCount),
                  ),
                  _DetailStat(
                    label: 'TỔNG ĐÃ BÁN',
                    value: Formatters.number(shop.totalSold),
                  ),
                  _DetailStat(
                    label: 'BÁN/THÁNG',
                    value: Formatters.number(shop.monthlySold),
                  ),
                  _DetailStat(
                    label: 'RATING TB',
                    value: shop.averageRating.toStringAsFixed(1),
                  ),
                  _DetailStat(
                    label: 'GIÁ TB',
                    value: Formatters.priceShort(shop.averagePrice),
                  ),
                  _DetailStat(
                    label: 'DOANH THU ƯỚC TÍNH',
                    value: Formatters.priceShort(shop.totalRevenueEstimate),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Sản phẩm của shop',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: productListHeight,
              child: shop.products.isEmpty
                  ? const _EmptyMessage(
                      message: 'Shop này chưa có sản phẩm trong Firestore.',
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        children: [
                          const SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: 870,
                              child: _ProductHeader(),
                            ),
                          ),
                          const Divider(color: AppColors.cardLight, height: 1),
                          SizedBox(
                            height: productRowsHeight,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: 870,
                                child: ListView.separated(
                                  itemCount: shop.products.length,
                                  separatorBuilder: (_, _) => const Divider(
                                    color: AppColors.cardLight,
                                    height: 1,
                                  ),
                                  itemBuilder: (context, index) => _ProductRow(
                                    product: shop.products[index],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;

  const _DetailStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardLight.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: const Row(
        children: [
          SizedBox(width: 44),
          SizedBox(
            width: 430,
            child: Text('TÊN SẢN PHẨM', style: _headerTextStyle),
          ),
          SizedBox(
            width: 90,
            child: Text(
              'GIÁ',
              textAlign: TextAlign.right,
              style: _headerTextStyle,
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              'ĐÃ BÁN',
              textAlign: TextAlign.right,
              style: _headerTextStyle,
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              'THÁNG',
              textAlign: TextAlign.right,
              style: _headerTextStyle,
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              'RATING',
              textAlign: TextAlign.right,
              style: _headerTextStyle,
            ),
          ),
          SizedBox(
            width: 62,
            child: Text(
              'LINK',
              textAlign: TextAlign.right,
              style: _headerTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;

  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: [
          _ProductThumbnail(url: product.thumbnailUrl),
          const SizedBox(width: 12),
          SizedBox(
            width: 430,
            child: Text(
              product.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              Formatters.priceShort(product.price),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              Formatters.number(product.soldCount),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              Formatters.number(product.monthlySoldCount),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              product.rating.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 62,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: product.url.isEmpty
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: product.url));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép URL sản phẩm'),
                          ),
                        );
                      },
                icon: const Icon(Icons.link, size: 18),
                color: AppColors.textSecondary,
                tooltip: 'Sao chép URL',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  final String? url;

  const _ProductThumbnail({this.url});

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        color: AppColors.background,
        child: imageUrl == null || imageUrl.isEmpty
            ? const Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.textSecondary,
                size: 18,
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String message;

  const _EmptyMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.accent, size: 42),
            const SizedBox(height: 12),
            const Text(
              'Không thể tải dữ liệu shop',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.cardLight.withValues(alpha: 0.75)),
  );
}

const _headerTextStyle = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.7,
);

extension _ShopSortOptionLabel on ShopSortOption {
  String get label {
    switch (this) {
      case ShopSortOption.productCount:
        return 'Số sản phẩm giảm dần';
      case ShopSortOption.totalSold:
        return 'Tổng đã bán giảm dần';
      case ShopSortOption.monthlySold:
        return 'Bán/tháng giảm dần';
      case ShopSortOption.averageRating:
        return 'Rating trung bình giảm dần';
      case ShopSortOption.averagePrice:
        return 'Giá trung bình giảm dần';
      case ShopSortOption.revenueEstimate:
        return 'Doanh thu ước tính giảm dần';
    }
  }
}
