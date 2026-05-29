import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/core/utils/formatters.dart';
import 'package:shopee_app/models/product.dart';
import 'package:shopee_app/providers/product_list_provider.dart';

class ProductListTable extends StatelessWidget {
  final ProductListProvider provider;
  final int? selectedProductId;
  final ValueChanged<Product> onProductSelected;
  final int currentPage;
  final int rowsPerPage;
  final ValueChanged<int> onPageChanged;

  const ProductListTable({
    super.key,
    required this.provider,
    required this.selectedProductId,
    required this.onProductSelected,
    required this.currentPage,
    this.rowsPerPage = 10,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final allProducts = provider.products;
    final totalPages = (allProducts.length / rowsPerPage).ceil();
    final startIndex = currentPage * rowsPerPage;
    final endIndex = min(startIndex + rowsPerPage, allProducts.length);
    final pageProducts = allProducts.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardLight.withValues(alpha: 0.75)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: pageProducts.isEmpty
                ? const Center(
                    child: Text(
                      'Không tìm thấy sản phẩm phù hợp',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    itemCount: pageProducts.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: AppColors.cardLight,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final product = pageProducts[index];
                      final isSelected = selectedProductId == product.productId;
                      return _ProductRowItem(
                        product: product,
                        shopName: provider.shopNameFor(product.shopId),
                        isSelected: isSelected,
                        isEven: index.isEven,
                        onTap: () => onProductSelected(product),
                      );
                    },
                  ),
          ),
          _PaginationBar(
            currentPage: currentPage,
            totalPages: totalPages,
            totalItems: allProducts.length,
            rowsPerPage: rowsPerPage,
            onPageChanged: onPageChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardLight)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 56,
            child: Text('ẢNH', style: _headerStyle, textAlign: TextAlign.center),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text('TÊN SẢN PHẨM', style: _headerStyle),
          ),
          Expanded(flex: 2, child: Text('SHOP', style: _headerStyle)),
          SizedBox(
            width: 100,
            child: Text('RATING', style: _headerStyle, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: 130,
            child: Text('GIÁ', style: _headerStyle, textAlign: TextAlign.right),
          ),
        ],
      ),
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
    final startItem = currentPage * rowsPerPage + 1;
    final endItem = min((currentPage + 1) * rowsPerPage, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardLight)),
      ),
      child: Row(
        children: [
          Text(
            'Hiện thị $startItem-$endItem trong số $totalItems sản phẩm',
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
          color: onTap != null ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _ProductRowItem extends StatelessWidget {
  final Product product;
  final String shopName;
  final bool isSelected;
  final bool isEven;
  final VoidCallback onTap;

  const _ProductRowItem({
    required this.product,
    required this.shopName,
    required this.isSelected,
    required this.isEven,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.accent.withValues(alpha: 0.12)
          : isEven
              ? Colors.transparent
              : AppColors.cardLight.withValues(alpha: 0.18),
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.accent.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 56,
                child: Align(
                  alignment: Alignment.center,
                  child: _ProductThumbnail(url: product.displayImageUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      if (product.isOfficialShop ||
                          product.isMart ||
                          product.showFreeShipping) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (product.isOfficialShop)
                              _badge('Official', AppColors.blue),
                            if (product.isMart) _badge('Mall', AppColors.accent),
                            if (product.showFreeShipping)
                              _badge('Freeship+', AppColors.green),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    shopName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 13, color: AppColors.orange),
                      const SizedBox(width: 3),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' (${product.ratingCount})',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 130,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.priceFull(product.price),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product.originalPrice != null && product.discount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Formatters.priceFull(product.originalPrice!),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '-${product.discount}%',
                              style: const TextStyle(
                                color: AppColors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.cardLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: imageUrl == null || imageUrl.isEmpty
            ? const Center(
                child: Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 20),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: 52,
                height: 52,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
      ),
    );
  }
}
