import 'package:flutter/material.dart';

import 'app_colors.dart';

/// アプリのテーマ設定（グレージュ基調）
class AppTheme {
  static ThemeData get lightTheme {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8A857C),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base.copyWith(
        surface: AppColors.canvas,
        onSurface: AppColors.ink,
        surfaceContainerHighest: AppColors.surfaceMuted,
        outline: AppColors.outline,
      ),
      scaffoldBackgroundColor: AppColors.canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      dividerColor: AppColors.outline,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8A857C),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base.copyWith(
        surface: AppColors.drawer,
        onSurface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.drawer,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.drawer,
        foregroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
    );
  }
}
