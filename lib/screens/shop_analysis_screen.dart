import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';

/// TODO: Team implement màn hình phân tích shop
class ShopAnalysisScreen extends StatelessWidget {
  const ShopAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.store, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'Phân tích Shop',
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
