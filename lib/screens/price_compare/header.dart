import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/core/utils/formatters.dart';
import 'package:shopee_app/providers/price_compare_provider.dart';

class PriceCompareHeader extends StatelessWidget {
  final PriceCompareProvider provider;
  final double width;

  const PriceCompareHeader({
    super.key,
    required this.provider,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final buttonWidth = width < 460 ? width : 132.0;
    final titleWidth =
        width < 460 ? width : math.max(0.0, width - buttonWidth - 16);

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
                'So sánh giá GPU',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Phân tích giá thị trường theo thời gian thực trên hệ sinh thái Shopee.',
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
