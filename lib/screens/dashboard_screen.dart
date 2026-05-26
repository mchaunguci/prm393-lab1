import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/core/utils/formatters.dart';
import 'package:shopee_app/providers/dashboard_provider.dart';
import 'package:shopee_app/widgets/stat_card.dart';
import 'package:shopee_app/widgets/price_chart.dart';
import 'package:shopee_app/widgets/location_chart.dart';
import 'package:shopee_app/widgets/top_products_table.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.accent),
                SizedBox(height: 16),
                Text('Đang tải dữ liệu từ Firestore...', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.accent, size: 48),
                const SizedBox(height: 12),
                Text('Lỗi: ${provider.error}', style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.loadData,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(provider),
                  const SizedBox(height: 24),
                  _buildStatCards(provider),
                  const SizedBox(height: 24),
                  _buildCharts(provider),
                  const SizedBox(height: 24),
                  _buildTables(provider),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            Positioned(
              left: 24,
              bottom: 24,
              child: _buildRefreshButton(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(DashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tổng quan thị trường GPU',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Dữ liệu thời gian thực từ hệ sinh thái Shopee Việt Nam',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards(DashboardProvider provider) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'TỔNG SẢN PHẨM',
            value: Formatters.number(provider.totalProducts),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'TỔNG SHOP',
            value: Formatters.number(provider.totalShops),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'GIÁ TRUNG BÌNH',
            value: Formatters.priceFull(provider.avgPrice),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'ĐÁNH GIÁ TRUNG BÌNH',
            value: provider.avgRating.toStringAsFixed(1),
            subtitle: '/ 5.0',
            icon: Icons.star,
          ),
        ),
      ],
    );
  }

  Widget _buildCharts(DashboardProvider provider) {
    return SizedBox(
      height: 280,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PriceDistributionChart(data: provider.priceDistribution),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: LocationPieChart(data: provider.locationDistribution),
          ),
        ],
      ),
    );
  }

  Widget _buildTables(DashboardProvider provider) {
    return SizedBox(
      height: 380,
      child: Row(
        children: [
          Expanded(
            child: TopSoldTable(
              products: provider.topBySold,
              shopNameResolver: provider.shopNameFor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TopDiscountTable(products: provider.topByDiscount),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(DashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          onPressed: provider.loadData,
          backgroundColor: AppColors.accent,
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: const Text('Làm mới dữ liệu', style: TextStyle(color: Colors.white)),
        ),
        if (provider.lastUpdated != null) ...[
          const SizedBox(height: 6),
          Text(
            '⏱ Dữ liệu cập nhật: ${Formatters.date(provider.lastUpdated)}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ],
    );
  }
}
