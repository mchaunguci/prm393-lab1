import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shopee_app/firebase_options.dart';
import 'package:shopee_app/core/constants/app_colors.dart';
import 'package:shopee_app/core/constants/app_constants.dart';
import 'package:shopee_app/providers/dashboard_provider.dart';
import 'package:shopee_app/providers/shop_analysis_provider.dart';
import 'package:shopee_app/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ShopeeApp());
}

class ShopeeApp extends StatelessWidget {
  const ShopeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider()..loadData()),
        ChangeNotifierProvider(
          create: (_) => ShopAnalysisProvider()..loadData(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          colorSchemeSeed: AppColors.accent,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
