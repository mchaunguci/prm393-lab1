import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.deepOrange,
      brightness: Brightness.light,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.deepOrange,
      brightness: Brightness.dark,
    );
  }
}
