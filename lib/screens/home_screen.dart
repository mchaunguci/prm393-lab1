import 'package:flutter/material.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/widgets/sidebar.dart';
import 'package:shopee_app/screens/dashboard_screen.dart';
import 'package:shopee_app/screens/products_screen.dart';
import 'package:shopee_app/screens/shop_analysis_screen.dart';
import 'package:shopee_app/screens/price_compare_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _screens = <Widget>[
    DashboardScreen(),
    ProductsScreen(),
    ShopAnalysisScreen(),
    PriceCompareScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (i) => setState(() => _selectedIndex = i),
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _screens[_selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: AppColors.surface,
      child: Row(
        children: [
          const Spacer(),
          const Icon(Icons.notifications_outlined, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 16),
          const Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 16),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}
