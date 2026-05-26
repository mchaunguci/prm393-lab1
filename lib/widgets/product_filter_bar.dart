import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/providers/product_list_provider.dart';

class ProductFilterBar extends StatelessWidget {
  final ProductListProvider provider;

  const ProductFilterBar({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'Tất cả',
            icon: Icons.apps,
            isActive: _noFilterActive,
            onTap: provider.clearFilters,
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: 'Official Shop',
            icon: Icons.verified_user,
            isActive: provider.isOfficialShop == true,
            onTap: () => provider.setFlags(
              official: provider.isOfficialShop == true ? null : true,
            ),
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: 'Lowest Price',
            icon: Icons.trending_down,
            isActive: provider.isLowestPrice == true,
            onTap: () => provider.setFlags(
              lowest: provider.isLowestPrice == true ? null : true,
            ),
          ),
          const Spacer(),
          _SortDropdown(provider: provider),
        ],
      ),
    );
  }

  bool get _noFilterActive =>
      provider.isOfficialShop == null &&
      provider.isLowestPrice == null &&
      provider.isShopeeChoice == null;
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  static const double _chipHeight = 36;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: _chipHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? AppColors.accent
                  : AppColors.textSecondary.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final ProductListProvider provider;

  const _SortDropdown({required this.provider});

  String get _sortLabel {
    switch (provider.sortBy) {
      case 'price':
        return 'Giá tăng dần';
      case 'rating':
        return 'Rating cao nhất';
      case 'sold':
        return 'Bán chạy nhất';
      case 'discount':
        return 'Giảm giá nhiều';
      default:
        return 'Tên A-Z';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => provider.setSort(value),
      offset: const Offset(0, 44),
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (_) => [
        _menuItem('name', 'Tên A-Z'),
        _menuItem('price', 'Giá tăng dần'),
        _menuItem('rating', 'Rating cao nhất'),
        _menuItem('sold', 'Bán chạy nhất'),
        _menuItem('discount', 'Giảm giá nhiều'),
      ],
      child: Container(
        height: 36,
        width: 170,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.sort, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _sortLabel,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label) {
    final isSelected = provider.sortBy == value;
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.accent : AppColors.textPrimary,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
