import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/providers/product_list_provider.dart';

class ProductFilterBar extends StatefulWidget {
  final ProductListProvider provider;
  final VoidCallback? onSearchChanged;

  const ProductFilterBar({
    super.key,
    required this.provider,
    this.onSearchChanged,
  });

  @override
  State<ProductFilterBar> createState() => _ProductFilterBarState();
}

class _ProductFilterBarState extends State<ProductFilterBar> {
  late TextEditingController _searchController;

  ProductListProvider get provider => widget.provider;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: provider.searchQuery);
  }

  @override
  void didUpdateWidget(ProductFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (provider.searchQuery != _searchController.text) {
      _searchController.text = provider.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    provider.setSearch(value);
    widget.onSearchChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildSearchField(),
              ),
            ),
            const SizedBox(width: 12),
            _FilterChip(
              label: 'Tất cả',
              icon: Icons.apps,
              isActive: _noFilterActive,
              onTap: () {
                _searchController.clear();
                provider.clearFilters();
                widget.onSearchChanged?.call();
              },
            ),
            const SizedBox(width: 8),
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
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          height: 1.2,
        ),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm theo tên sản phẩm...',
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.8),
            fontSize: 13,
            height: 1.2,
          ),
          isDense: true,
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: AppColors.textSecondary,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 36,
          ),
          suffixIcon: provider.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  bool get _noFilterActive =>
      provider.searchQuery.isEmpty &&
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
        return provider.sortAsc ? 'Giá tăng dần' : 'Giá giảm dần';
      case 'rating':
        return 'Rating cao nhất';
      case 'sold':
        return 'Bán chạy nhất';
      case 'discount':
        return 'Giảm giá nhiều';
      default:
        return 'Giá tăng dần';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: AppColors.cardLight.withValues(alpha: 0.35),
        hoverColor: AppColors.cardLight.withValues(alpha: 0.25),
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: AppColors.cardLight.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
      child: PopupMenuButton<String>(
        onSelected: (value) => provider.setSort(value),
        offset: const Offset(0, 44),
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: AppColors.cardLight.withValues(alpha: 0.75),
          ),
        ),
        itemBuilder: (_) => [
          _menuItem('price_asc', 'Giá tăng dần'),
          _menuItem('price_desc', 'Giá giảm dần'),
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
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label) {
    final isSelected = switch (value) {
      'price_asc' => provider.sortBy == 'price' && provider.sortAsc,
      'price_desc' => provider.sortBy == 'price' && !provider.sortAsc,
      _ => provider.sortBy == value,
    };
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.accent : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
