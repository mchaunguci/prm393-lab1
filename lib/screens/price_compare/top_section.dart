import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/providers/price_compare_provider.dart';
import 'package:shopee_app/screens/price_compare/best_deal_card.dart';
import 'package:shopee_app/screens/price_compare/shared.dart';

class PriceCompareTopSection extends StatelessWidget {
  final PriceCompareProvider provider;
  final double width;

  const PriceCompareTopSection({
    super.key,
    required this.provider,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    const bestDealWidth = 288.0;
    final wide = width >= 880;

    if (wide) {
      final tabsWidth = math.max(0.0, width - bestDealWidth - 16);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: tabsWidth,
            child: _ModelTabsArea(provider: provider, width: tabsWidth),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: bestDealWidth,
            child: BestDealCard(provider: provider),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BestDealCard(provider: provider),
        const SizedBox(height: 16),
        _ModelTabsArea(provider: provider, width: width),
      ],
    );
  }
}

class _ModelTabsArea extends StatelessWidget {
  final PriceCompareProvider provider;
  final double width;

  const _ModelTabsArea({required this.provider, required this.width});

  @override
  Widget build(BuildContext context) {
    final models = provider.modelGroups;
    final count = provider.filteredProducts.length;

    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: models.map((model) {
                final selected = model == provider.selectedModel;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ModelTabChip(
                    label: model.replaceFirst('RTX ', ''),
                    isSelected: selected,
                    onTap: () => provider.selectModel(model),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Đang hiển thị $count sản phẩm ${provider.selectedModel}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelTabChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModelTabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.cardLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
