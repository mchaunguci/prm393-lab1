import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';

BoxDecoration cardDecoration() {
  return BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.cardLight.withValues(alpha: 0.75)),
  );
}

class DiscountBadge extends StatelessWidget {
  final int discount;

  const DiscountBadge({super.key, required this.discount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '-$discount%',
        style: const TextStyle(
          color: AppColors.green,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ProductThumbnail extends StatelessWidget {
  final String? url;
  final double size;

  const ProductThumbnail({super.key, this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        color: AppColors.background,
        child: imageUrl == null || imageUrl.isEmpty
            ? Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.textSecondary,
                size: size * 0.48,
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textSecondary,
                  size: size * 0.48,
                ),
              ),
      ),
    );
  }
}

class PriceTableCell extends StatelessWidget {
  final double width;
  final String text;
  final bool isHeader;
  final bool alignRight;

  const PriceTableCell({
    super.key,
    required this.width,
    required this.text,
    this.isHeader = false,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final text_ = Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        color: isHeader ? AppColors.textSecondary : AppColors.textPrimary,
        fontSize: isHeader ? 10 : 12,
        fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
        letterSpacing: isHeader ? 0.6 : 0,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (width <= 0) return text_;
    return SizedBox(width: width, child: text_);
  }
}

class EmptyMessage extends StatelessWidget {
  final String message;

  const EmptyMessage({super.key, required this.message});

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

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        decoration: cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.accent, size: 42),
            const SizedBox(height: 12),
            const Text(
              'Không thể tải dữ liệu',
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
