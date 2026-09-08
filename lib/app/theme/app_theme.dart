import 'package:flutter/material.dart';

abstract final class AppColors {
  static const morningMist = Color(0xFFF7FCFB);
  static const white = Color(0xFFFFFFFF);
  static const mintWash = Color(0xFFE6F5F3);
  static const deepOcean = Color(0xFF17343D);
  static const muted = Color(0xFF657F85);
  static const freshMint = Color(0xFF69CFBD);
  static const clearSky = Color(0xFF5D9FDA);
  static const paleAqua = Color(0xFFD6F7EF);
  static const border = Color(0xFFCFE4E2);
  static const danger = Color(0xFFC95D5D);
  static const ocean950 = Color(0xFF102F38);
  static const supportTeal = Color(0xFF3B7B85);
  static const coralFocus = Color(0xFFEC6557);
  static const controlBorder = Color(0xFF739B96);
  static const mapWater = Color(0xFFABDCE2);
  static const mapWaterLight = Color(0xFFD9EEF1);
  static const mapLeaf = Color(0xFFE5F0DF);
  static const mapLeafDark = Color(0xFFB8DCAE);
  static const mapRoute = Color(0xFF2E7892);
}

abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.freshMint,
      onPrimary: AppColors.deepOcean,
      secondary: AppColors.clearSky,
      onSecondary: AppColors.deepOcean,
      surface: AppColors.white,
      onSurface: AppColors.deepOcean,
      error: AppColors.danger,
      onError: AppColors.white,
      outline: AppColors.border,
    );

    final base = ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.morningMist,
      useMaterial3: true,
      fontFamilyFallback: const [
        'PingFang SC',
        'Noto Sans CJK SC',
        'sans-serif',
      ],
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.deepOcean,
        displayColor: AppColors.deepOcean,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.morningMist,
        foregroundColor: AppColors.deepOcean,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        hintStyle: const TextStyle(color: AppColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.clearSky, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          foregroundColor: AppColors.deepOcean,
          backgroundColor: AppColors.freshMint,
          disabledForegroundColor: AppColors.muted,
          disabledBackgroundColor: AppColors.mintWash,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          foregroundColor: const Color(0xFF2C8277),
          side: const BorderSide(color: Color(0xFF8BD3C7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.freshMint
              : AppColors.white;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.deepOcean),
        side: const BorderSide(color: AppColors.muted),
      ),
    );
  }
}
