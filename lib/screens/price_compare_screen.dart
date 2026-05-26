import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';

/// TODO: Team implement màn hình so sánh giá
class PriceCompareScreen extends StatelessWidget {
  const PriceCompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.price_change, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'So sánh giá',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Chức năng đang được phát triển...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
