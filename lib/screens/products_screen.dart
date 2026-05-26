import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';

/// TODO: Team implement màn hình danh sách sản phẩm
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'Sản phẩm',
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
