import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/core/utils/formatters.dart';
import 'package:shopee_app/models/product.dart';
import 'package:shopee_app/providers/product_list_provider.dart';

class ProductDetailPanel extends StatelessWidget {
  final Product product;
  final ProductListProvider provider;

  const ProductDetailPanel({
    super.key,
    required this.product,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardLight.withValues(alpha: 0.75)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            const SizedBox(height: 16),
            _buildCategory(),
            const SizedBox(height: 8),
            _buildName(),
            const SizedBox(height: 12),
            _buildPrice(),
            const SizedBox(height: 16),
            _buildStats(),
            const SizedBox(height: 16),
            _buildShopInfo(),
            const SizedBox(height: 16),
            _buildFlags(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 1,
        child: product.displayImageUrl != null
            ? Image.network(
                product.displayImageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.cardLight,
                  child: const Icon(Icons.image, color: AppColors.textSecondary, size: 48),
                ),
              )
            : Container(
                color: AppColors.cardLight,
                child: const Icon(Icons.image, color: AppColors.textSecondary, size: 48),
              ),
      ),
    );
  }

  Widget _buildCategory() {
    return Text(
      'DANH MỤC: LINH KIỆN MÁY TÍNH',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildName() {
    return Text(
      product.name,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPrice() {
    return Row(
      children: [
        Text(
          Formatters.priceFull(product.price),
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (product.discount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '-${product.discount}% OFF',
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _statBox('ĐÃ BÁN (THÁNG)', '${product.monthlySoldCount} SP'),
        const SizedBox(width: 12),
        _statBox(
          'LƯỢT TRUY CẬP',
          Formatters.priceShort(product.likedCount.toDouble()),
        ),
      ],
    );
  }

  Widget _buildShopInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'THÔNG TIN SHOP',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.cardLight,
              child: const Icon(
                Icons.store,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.shopNameFor(product.shopId),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                if (product.isOfficialShop)
                  const Text(
                    'Official Store',
                    style: TextStyle(color: AppColors.blue, fontSize: 11),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFlags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TÙY CHỌN & CAM KẾT',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (product.canUseCod) _infoChip(Icons.payment, 'Thanh toán COD'),
            if (product.showFreeShipping)
              _infoChip(Icons.local_shipping, 'Free Ship'),
            if (product.isShopeeChoice)
              _infoChip(Icons.verified, 'Shopee Choice'),
            if (product.hasLowestPriceGuarantee)
              _infoChip(Icons.price_check, 'Giá rẻ nhất'),
          ],
        ),
      ],
    );
  }

  Widget _statBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
