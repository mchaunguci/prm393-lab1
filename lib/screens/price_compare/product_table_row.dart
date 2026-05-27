import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/core/utils/formatters.dart';
import 'package:shopee_app/models/product.dart';
import 'package:shopee_app/screens/price_compare/shared.dart';

class ProductTableHeader extends StatelessWidget {
  const ProductTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardLight.withValues(alpha: 0.55),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: PriceTableCell(
              width: 0,
              text: 'TÊN SẢN PHẨM',
              isHeader: true,
            ),
          ),
          Expanded(
            flex: 2,
            child: PriceTableCell(width: 0, text: 'SHOP', isHeader: true),
          ),
          PriceTableCell(
            width: 110,
            text: 'GIÁ BÁN',
            isHeader: true,
            alignRight: true,
          ),
          PriceTableCell(
            width: 110,
            text: 'GIÁ GỐC',
            isHeader: true,
            alignRight: true,
          ),
          PriceTableCell(
            width: 72,
            text: 'GIẢM%',
            isHeader: true,
            alignRight: true,
          ),
          PriceTableCell(
            width: 80,
            text: 'RATING',
            isHeader: true,
            alignRight: true,
          ),
          PriceTableCell(
            width: 90,
            text: 'ĐÃ BÁN',
            isHeader: true,
            alignRight: true,
          ),
          PriceTableCell(
            width: 110,
            text: 'TIỆN ÍCH',
            isHeader: true,
            alignRight: true,
          ),
        ],
      ),
    );
  }
}

class ProductTableRow extends StatelessWidget {
  final Product product;
  final String shopName;

  const ProductTableRow({
    super.key,
    required this.product,
    required this.shopName,
  });

  @override
  Widget build(BuildContext context) {
    final origPrice = product.originalPrice ?? product.priceBeforeDiscount;
    final hasOrig = origPrice != null && origPrice > product.price;

    return Material(
      color: product.isLowestPrice
          ? AppColors.green.withValues(alpha: 0.05)
          : Colors.transparent,
      child: InkWell(
        hoverColor: AppColors.cardLight.withValues(alpha: 0.35),
        onTap: null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.cardLight, width: 0.7),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ProductThumbnail(url: product.thumbnailUrl, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
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
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        shopName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 110,
                child: Text(
                  Formatters.priceFull(product.price),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: product.isLowestPrice
                        ? AppColors.accent
                        : AppColors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 110,
                child: Text(
                  hasOrig ? Formatters.priceFull(origPrice) : '-',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    decoration: hasOrig ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: 72,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: product.discount > 0
                      ? DiscountBadge(discount: product.discount)
                      : const Text(
                          '-',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.star, color: AppColors.orange, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      product.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 90,
                child: Text(
                  product.soldCountText ?? _formatSold(product.soldCount),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(width: 110, child: _UtilityIcons(product: product)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSold(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k+';
    return count.toString();
  }
}

class _UtilityIcons extends StatelessWidget {
  final Product product;

  const _UtilityIcons({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (product.canUseCod) ...[
          _MiniChip(label: 'COD', color: AppColors.green),
          const SizedBox(width: 4),
        ],
        if (product.showFreeShipping) ...[
          _MiniChip(label: 'Ship0', color: AppColors.blue),
          const SizedBox(width: 4),
        ],
        SizedBox(
          width: 28,
          height: 28,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 15,
            onPressed: product.url.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: product.url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép URL sản phẩm'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
            icon: const Icon(Icons.link),
            color: AppColors.textSecondary,
            tooltip: 'Sao chép link',
          ),
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
