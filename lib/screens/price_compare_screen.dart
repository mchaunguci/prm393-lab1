import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/providers/price_compare_provider.dart';
import 'package:shopee_app/screens/price_compare/header.dart';
import 'package:shopee_app/screens/price_compare/price_chart_card.dart';
import 'package:shopee_app/screens/price_compare/product_table_card.dart';
import 'package:shopee_app/screens/price_compare/shared.dart';
import 'package:shopee_app/screens/price_compare/top_section.dart';

class PriceCompareScreen extends StatelessWidget {
  const PriceCompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PriceCompareProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.accent),
                SizedBox(height: 16),
                Text(
                  'Đang tải dữ liệu giá...',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        if (provider.error != null) {
          return ErrorState(
            message: provider.error!,
            onRetry: provider.loadData,
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = math.max(0.0, constraints.maxWidth - 48);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PriceCompareHeader(provider: provider, width: w),
                    const SizedBox(height: 24),
                    PriceCompareTopSection(provider: provider, width: w),
                    const SizedBox(height: 20),
                    PriceChartCard(provider: provider, width: w),
                    const SizedBox(height: 20),
                    ProductTableCard(provider: provider, width: w),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
