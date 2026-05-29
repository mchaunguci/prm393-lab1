import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/core/utils/formatters.dart';
import 'package:shopee_app/models/product.dart';

class KeywordResultsTable extends StatelessWidget {
  final List<Product> products;
  final String Function(int shopId) shopNameFor;
  final int currentPage;
  final int rowsPerPage;
  final ValueChanged<int> onPageChanged;

  const KeywordResultsTable({
    super.key,
    required this.products,
    required this.shopNameFor,
    required this.currentPage,
    this.rowsPerPage = 15,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = max(1, (products.length / rowsPerPage).ceil());
    final page = currentPage.clamp(0, totalPages - 1);
    final start = page * rowsPerPage;
    final pageProducts = products.skip(start).take(rowsPerPage).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Text(
                  'Kết quả tìm kiếm',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _miniStat('Giá thấp nhất', Formatters.priceFull(_minPrice(products))),
                const SizedBox(width: 20),
                _miniStat('Giá cao nhất', Formatters.priceFull(_maxPrice(products))),
                const SizedBox(width: 20),
                _miniStat('Giảm giá TB', '${_avgDiscount(products).toStringAsFixed(0)}%'),
                const SizedBox(width: 20),
                _miniStat('Official', '${products.where((p) => p.isOfficialShop).length}'),
              ],
            ),
          ),
          const Divider(color: AppColors.cardLight, height: 1),
          _header(),
          const Divider(color: AppColors.cardLight, height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: pageProducts.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: AppColors.cardLight, height: 1),
              itemBuilder: (_, index) => _row(pageProducts[index], index.isEven),
            ),
          ),
          _PaginationBar(
            currentPage: page,
            totalPages: totalPages,
            totalItems: products.length,
            rowsPerPage: rowsPerPage,
            onPageChanged: onPageChanged,
          ),
        ],
      ),
    );
  }

  static double _minPrice(List<Product> products) {
    if (products.isEmpty) return 0;
    return products.map((p) => p.price).reduce(min);
  }

  static double _maxPrice(List<Product> products) {
    if (products.isEmpty) return 0;
    return products.map((p) => p.price).reduce(max);
  }

  static double _avgDiscount(List<Product> products) {
    final discounted = products.where((p) => p.discount > 0).toList();
    if (discounted.isEmpty) return 0;
    return discounted.map((p) => p.discount.toDouble()).reduce((a, b) => a + b) /
        discounted.length;
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _header() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 48, child: Text('ẢNH', style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 12),
          Expanded(flex: 4, child: Text('TÊN SẢN PHẨM', style: _headerStyle)),
          Expanded(flex: 2, child: Text('SHOP', style: _headerStyle)),
          SizedBox(width: 88, child: Text('RATING', style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 120, child: Text('GIÁ', style: _headerStyle, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _row(Product product, bool isEven) {
    final imageUrl = product.displayImageUrl;
    return Container(
      color: isEven ? Colors.transparent : AppColors.cardLight.withValues(alpha: 0.18),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.35),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              shopNameFor(product.shopId),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 88,
            child: Text(
              product.ratingCount > 0
                  ? '⭐ ${product.rating.toStringAsFixed(1)} (${product.ratingCount})'
                  : '—',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.priceFull(product.price),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (product.discount > 0)
                  Text(
                    '-${product.discount}%',
                    style: const TextStyle(color: AppColors.green, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.cardLight,
      child: const Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 20),
    );
  }

  static const _headerStyle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int rowsPerPage;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.rowsPerPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final startItem = totalItems == 0 ? 0 : currentPage * rowsPerPage + 1;
    final endItem = min((currentPage + 1) * rowsPerPage, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardLight)),
      ),
      child: Row(
        children: [
          Text(
            'Hiển thị $startItem-$endItem trong số $totalItems sản phẩm',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const Spacer(),
          _pageButton(
            icon: Icons.chevron_left,
            onTap: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
          ),
          const SizedBox(width: 4),
          ..._buildPageNumbers(),
          const SizedBox(width: 4),
          _pageButton(
            icon: Icons.chevron_right,
            onTap: currentPage < totalPages - 1
                ? () => onPageChanged(currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final pages = <Widget>[];
    const maxVisible = 5;

    int start = max(0, currentPage - maxVisible ~/ 2);
    int end = min(totalPages, start + maxVisible);
    if (end - start < maxVisible) {
      start = max(0, end - maxVisible);
    }

    if (start > 0) {
      pages.add(_pageNumber(0));
      if (start > 1) pages.add(_ellipsis());
    }

    for (int i = start; i < end; i++) {
      pages.add(_pageNumber(i));
    }

    if (end < totalPages) {
      if (end < totalPages - 1) pages.add(_ellipsis());
      pages.add(_pageNumber(totalPages - 1));
    }

    return pages;
  }

  Widget _pageNumber(int page) {
    final isActive = page == currentPage;
    return GestureDetector(
      onTap: () => onPageChanged(page),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          '${page + 1}',
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _ellipsis() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text('...', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    );
  }

  Widget _pageButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null
              ? AppColors.textPrimary
              : AppColors.textSecondary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
