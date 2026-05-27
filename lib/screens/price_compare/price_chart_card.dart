import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/core/utils/formatters.dart';
import 'package:shopee_app/models/product.dart';
import 'package:shopee_app/providers/price_compare_provider.dart';
import 'package:shopee_app/screens/price_compare/shared.dart';

class PriceChartCard extends StatelessWidget {
  final PriceCompareProvider provider;
  final double width;

  const PriceChartCard({
    super.key,
    required this.provider,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final products = provider.filteredProducts;
    final priceMin = provider.priceMin;
    final priceMax = provider.priceMax;
    final avgPrice = provider.avgPrice;
    final bestDeal = provider.bestDeal;

    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Phân phối giá thị trường',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (products.isNotEmpty)
                    Text(
                      'Trục giá: ${Formatters.priceShort(priceMin)} ~ ${Formatters.priceShort(priceMax)} VND',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  _LegendDot(color: AppColors.orange),
                  const SizedBox(width: 5),
                  const Text(
                    'Giá tốt nhất',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 14),
                  _LegendDot(color: AppColors.blue),
                  const SizedBox(width: 5),
                  const Text(
                    'Giá trung bình',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            const SizedBox(
              height: 80,
              child: EmptyMessage(message: 'Không có dữ liệu giá'),
            )
          else
            SizedBox(
              height: 110,
              child: CustomPaint(
                size: Size(width - 40, 110),
                painter: _PriceDotPainter(
                  products: products,
                  priceMin: priceMin,
                  priceMax: priceMax,
                  avgPrice: avgPrice,
                  bestDeal: bestDeal,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;

  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _PriceDotPainter extends CustomPainter {
  final List<Product> products;
  final double priceMin;
  final double priceMax;
  final double avgPrice;
  final Product? bestDeal;

  static const _paddingH = 24.0;
  static const _axisY = 62.0;

  _PriceDotPainter({
    required this.products,
    required this.priceMin,
    required this.priceMax,
    required this.avgPrice,
    required this.bestDeal,
  });

  double _xForPrice(double price, double usableWidth) {
    if (priceMax == priceMin) return _paddingH + usableWidth * 0.5;
    final t = (price - priceMin) / (priceMax - priceMin);
    return _paddingH + t.clamp(0.0, 1.0) * usableWidth;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final usableWidth = size.width - _paddingH * 2;

    final axisPaint = Paint()
      ..color = AppColors.cardLight
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(_paddingH, _axisY),
      Offset(size.width - _paddingH, _axisY),
      axisPaint,
    );

    for (final p in products) {
      if (p == bestDeal) continue;
      final x = _xForPrice(p.price, usableWidth);
      final color =
          p.price <= avgPrice ? AppColors.blue : AppColors.textSecondary;
      final radius = p.price <= avgPrice ? 7.0 : 6.0;
      canvas.drawCircle(
        Offset(x, _axisY),
        radius,
        Paint()..color = color.withValues(alpha: 0.75),
      );
    }

    if (bestDeal != null) {
      final x = _xForPrice(bestDeal!.price, usableWidth);

      canvas.drawCircle(
        Offset(x, _axisY),
        14,
        Paint()..color = AppColors.orange.withValues(alpha: 0.18),
      );
      canvas.drawCircle(
        Offset(x, _axisY),
        9,
        Paint()..color = AppColors.orange,
      );

      final labelText =
          'Giá tốt nhất: ${Formatters.priceShort(bestDeal!.price)}';
      final tp = TextPainter(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(
            color: AppColors.orange,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelX = (x - tp.width / 2).clamp(
        _paddingH,
        size.width - _paddingH - tp.width,
      );
      const labelY = 6.0;
      final rect = Rect.fromLTWH(
        labelX - 6,
        labelY - 2,
        tp.width + 12,
        tp.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..color = AppColors.orange.withValues(alpha: 0.15),
      );
      tp.paint(canvas, Offset(labelX, labelY));
    }

    final step = (priceMax - priceMin) / 4;
    for (int i = 0; i < 5; i++) {
      final price = priceMin + step * i;
      final x = _paddingH + (i / 4) * usableWidth;
      final tp = TextPainter(
        text: TextSpan(
          text: Formatters.priceShort(price),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelX = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(labelX, _axisY + 12));
    }
  }

  @override
  bool shouldRepaint(_PriceDotPainter old) =>
      old.products != products ||
      old.priceMin != priceMin ||
      old.priceMax != priceMax ||
      old.bestDeal != bestDeal;
}
