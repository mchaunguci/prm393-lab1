import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/models/product.dart';
import 'package:shopee_app/providers/product_list_provider.dart';
import 'package:shopee_app/widgets/product_filter_bar.dart';
import 'package:shopee_app/widgets/product_list_table.dart';
import 'package:shopee_app/widgets/product_detail_panel.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  Product? _selectedProduct;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductListProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.accent,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Lỗi: ${provider.error}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.loadData,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final totalPages = (provider.products.length / 15).ceil();
        if (_currentPage >= totalPages && totalPages > 0) {
          _currentPage = totalPages - 1;
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(provider),
              const SizedBox(height: 20),
              ProductFilterBar(
                provider: provider,
                onSearchChanged: () => setState(() => _currentPage = 0),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 7,
                      child: ProductListTable(
                        provider: provider,
                        selectedProductId: _selectedProduct?.productId,
                        onProductSelected: (product) {
                          setState(() => _selectedProduct = product);
                        },
                        currentPage: _currentPage,
                        rowsPerPage: 15,
                        onPageChanged: (page) {
                          setState(() => _currentPage = page);
                        },
                      ),
                    ),
                    if (_selectedProduct != null) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: ProductDetailPanel(
                          product: _selectedProduct!,
                          provider: provider,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ProductListProvider provider) {
    final filtered = provider.products.length;
    final total = provider.totalProducts;
    final subtitle = filtered == total
        ? '$total sản phẩm · ${provider.shops.length} shop trên Shopee'
        : '$filtered / $total sản phẩm · ${provider.shops.length} shop';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh sách sản phẩm',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
