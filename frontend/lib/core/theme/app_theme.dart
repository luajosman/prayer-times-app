import 'package:flutter/material.dart';
import 'package:frontend/src/core/design_tokens.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.dark,
      // Primary — muted emerald
      primary:             AppColors.primary,
      onPrimary:           AppColors.textPrimary,
      primaryContainer:    Color(0xFF1A4A3E),
      onPrimaryContainer:  AppColors.primaryLight,
      // Secondary — restrained gold
      secondary:              AppColors.gold,
      onSecondary:            Color(0xFF2A1F08),
      secondaryContainer:     Color(0xFF3A2D10),
      onSecondaryContainer:   AppColors.goldLight,
      // Tertiary — informational blue
      tertiary:             AppColors.info,
      onTertiary:           AppColors.background,
      tertiaryContainer:    Color(0xFF1A3245),
      onTertiaryContainer:  AppColors.info,
      // Error
      error:            AppColors.error,
      onError:          AppColors.textPrimary,
      errorContainer:   Color(0xFF4A1A1A),
      onErrorContainer: Color(0xFFFFB4AB),
      // Surface hierarchy
      surface:             AppColors.surface,
      onSurface:           AppColors.textPrimary,
      onSurfaceVariant:    AppColors.textSecondary,
      surfaceTint:         Colors.transparent,
      // Outlines
      outline:         AppColors.border,
      outlineVariant:  AppColors.borderSubtle,
      // Misc
      scrim:           Color(0xFF000000),
      inverseSurface:  AppColors.textPrimary,
      onInverseSurface: AppColors.background,
      inversePrimary:  AppColors.primaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _textTheme(),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textSecondary, size: 22),
        actionsIconTheme: IconThemeData(color: AppColors.textSecondary, size: 22),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide:
              const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(
            color: AppColors.textSecondary, fontSize: 13),
        hintStyle: const TextStyle(
            color: AppColors.textTertiary, fontSize: 14),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: AppColors.surfaceHigh,
          disabledForegroundColor: AppColors.textTertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceHigh,
        selectedColor: AppColors.primary.withValues(alpha: 0.22),
        disabledColor: AppColors.surfaceHigh.withValues(alpha: 0.5),
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.primaryLight,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        showCheckmark: false,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: const TextStyle(
            color: AppColors.textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      iconTheme:
          const IconThemeData(color: AppColors.textSecondary, size: 22),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        elevation: 4,
      ),
    );
  }

  static TextTheme _textTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        color: AppColors.textPrimary, fontSize: 56,
        fontWeight: FontWeight.w300, letterSpacing: -1.5,
      ),
      displayMedium: TextStyle(
        color: AppColors.textPrimary, fontSize: 44,
        fontWeight: FontWeight.w300, letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        color: AppColors.textPrimary, fontSize: 36,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: TextStyle(
        color: AppColors.textPrimary, fontSize: 30,
        fontWeight: FontWeight.w600, letterSpacing: -0.3,
      ),
      headlineMedium: TextStyle(
        color: AppColors.textPrimary, fontSize: 26,
        fontWeight: FontWeight.w600, letterSpacing: -0.2,
      ),
      headlineSmall: TextStyle(
        color: AppColors.textPrimary, fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimary, fontSize: 18,
        fontWeight: FontWeight.w600, letterSpacing: 0.1,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimary, fontSize: 15,
        fontWeight: FontWeight.w500, letterSpacing: 0.1,
      ),
      titleSmall: TextStyle(
        color: AppColors.textSecondary, fontSize: 13,
        fontWeight: FontWeight.w500, letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textPrimary, fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondary, fontSize: 14,
        fontWeight: FontWeight.w400, height: 1.45,
      ),
      bodySmall: TextStyle(
        color: AppColors.textTertiary, fontSize: 12,
        fontWeight: FontWeight.w400, letterSpacing: 0.2,
      ),
      labelLarge: TextStyle(
        color: AppColors.textPrimary, fontSize: 14,
        fontWeight: FontWeight.w600, letterSpacing: 0.4,
      ),
      labelMedium: TextStyle(
        color: AppColors.textSecondary, fontSize: 12,
        fontWeight: FontWeight.w500, letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        color: AppColors.textTertiary, fontSize: 10,
        fontWeight: FontWeight.w500, letterSpacing: 0.8,
      ),
    );
  }
}
