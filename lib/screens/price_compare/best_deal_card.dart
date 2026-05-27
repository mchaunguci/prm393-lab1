import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/core/utils/formatters.dart';
import 'package:shopee_app/providers/price_compare_provider.dart';
import 'package:shopee_app/screens/price_compare/shared.dart';

class BestDealCard extends StatelessWidget {
  final PriceCompareProvider provider;

  const BestDealCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final deal = provider.bestDeal;
    if (deal == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: cardDecoration(),
        child: const EmptyMessage(message: 'Không có dữ liệu gợi ý'),
      );
    }

    final shopName = provider.shopNameFor(deal.shopId);
    final isOfficial = provider.isOfficialShopId(deal.shopId);
    final origPrice = deal.originalPrice ?? deal.priceBeforeDiscount;
    final hasDiscount =
        deal.discount > 0 && origPrice != null && origPrice > deal.price;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductThumbnail(url: deal.thumbnailUrl, size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (isOfficial)
                              const Icon(
                                Icons.verified,
                                color: AppColors.blue,
                                size: 13,
                              ),
                            if (isOfficial) const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                shopName,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.priceFull(deal.price),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hasDiscount) ...[
                    const SizedBox(width: 8),
                    Text(
                      Formatters.priceFull(origPrice),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (hasDiscount) DiscountBadge(discount: deal.discount),
                  if (hasDiscount) const SizedBox(width: 8),
                  if (isOfficial)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha: 0.12),
                        border: Border.all(color: AppColors.blue),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'SHOPEE MALL',
                        style: TextStyle(
                          color: AppColors.blue,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: OutlinedButton(
                  onPressed: deal.url.isEmpty
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: deal.url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã sao chép link sản phẩm'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.cardLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'Xem chi tiết Shop',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomRight: Radius.circular(8),
              ),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'GỢI Ý TỐT NHẤT',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
