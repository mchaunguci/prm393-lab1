import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/core/utils/formatters.dart';
import 'package:shopee_app/models/product.dart';

class TopSoldTable extends StatelessWidget {
  final List<Product> products;
  final String Function(int shopId) shopNameResolver;

  const TopSoldTable({
    super.key,
    required this.products,
    required this.shopNameResolver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Top 5 bán chạy nhất',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '30 ngày qua',
                  style: TextStyle(color: AppColors.accent, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _header(),
          const Divider(color: AppColors.cardLight, height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: products.length,
              separatorBuilder: (context, index) => const Divider(color: AppColors.cardLight, height: 1),
              itemBuilder: (_, i) => _row(i, products[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('#', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
          Expanded(flex: 3, child: Text('TÊN SẢN PHẨM', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('SHOP', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
          SizedBox(width: 60, child: Text('ĐÃ BÁN', textAlign: TextAlign.right, style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
          SizedBox(width: 80, child: Text('GIÁ', textAlign: TextAlign.right, style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _row(int index, Product p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '#${index + 1}',
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              p.name,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              shopNameResolver(p.shopId),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              Formatters.number(p.monthlySoldCount),
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              Formatters.priceShort(p.price),
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class TopDiscountTable extends StatelessWidget {
  final List<Product> products;

  const TopDiscountTable({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Top 5 giảm giá sâu',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Flash Sale Live',
                  style: TextStyle(color: AppColors.accent, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _header(),
          const Divider(color: AppColors.cardLight, height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: products.length,
              separatorBuilder: (context, index) => const Divider(color: AppColors.cardLight, height: 1),
              itemBuilder: (_, i) => _row(i, products[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('#', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
          Expanded(flex: 3, child: Text('TÊN SẢN PHẨM', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
          SizedBox(width: 70, child: Text('GIÁ GỐC', textAlign: TextAlign.right, style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
          SizedBox(width: 70, child: Text('GIÁ BÁN', textAlign: TextAlign.right, style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
          SizedBox(width: 55, child: Text('GIẢM %', textAlign: TextAlign.right, style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _row(int index, Product p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '#${index + 1}',
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              p.name,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              Formatters.priceShort(p.originalPrice ?? p.price),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              Formatters.priceShort(p.price),
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 55,
            child: Text(
              '-${p.discountText ?? '${p.discount}%'}',
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
