import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color background = Color(0xFF081225);
  static const Color surface = Color(0xFF0F1B31);
  static const Color surfaceRaised = Color(0xFF13233D);
  static const Color surfaceStrong = Color(0xFF182B49);
  static const Color border = Color(0xFF243A5A);
  static const Color borderSubtle = Color(0xFF1B2F4C);

  static const Color textPrimary = Color(0xFFF4F7FB);
  static const Color textSecondary = Color(0xFFA9B7CB);
  static const Color textTertiary = Color(0xFF73839B);

  static const Color primary = Color(0xFF2F8C78);
  static const Color primarySoft = Color(0xFF63B7A1);
  static const Color primaryTint = Color(0xFF16372F);

  static const Color gold = Color(0xFFD6AE63);
  static const Color goldSoft = Color(0xFF8C6A2F);
  static const Color goldTint = Color(0xFF2E2618);

  static const Color success = Color(0xFF4BAE75);
  static const Color warning = Color(0xFFD89A3D);
  static const Color error = Color(0xFFD46262);
  static const Color info = Color(0xFF5C9FE8);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static Color overlay(Color accent, Color base, double opacity) {
    return Color.alphaBlend(accent.withValues(alpha: opacity), base);
  }
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceStrong,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.primarySoft,
    required this.primaryTint,
    required this.gold,
    required this.goldSoft,
    required this.goldTint,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.white,
    required this.black,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceStrong;
  final Color border;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color primary;
  final Color primarySoft;
  final Color primaryTint;
  final Color gold;
  final Color goldSoft;
  final Color goldTint;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color white;
  final Color black;

  static const AppPalette dark = AppPalette(
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceRaised: AppColors.surfaceRaised,
    surfaceStrong: AppColors.surfaceStrong,
    border: AppColors.border,
    borderSubtle: AppColors.borderSubtle,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    primary: AppColors.primary,
    primarySoft: AppColors.primarySoft,
    primaryTint: AppColors.primaryTint,
    gold: AppColors.gold,
    goldSoft: AppColors.goldSoft,
    goldTint: AppColors.goldTint,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    white: AppColors.white,
    black: AppColors.black,
  );

  static const AppPalette light = AppPalette(
    background: Color(0xFFF2F6FA),
    surface: Color(0xFFF8FBFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceStrong: Color(0xFFEAF0F7),
    border: Color(0xFFD5E0EC),
    borderSubtle: Color(0xFFE5EBF2),
    textPrimary: Color(0xFF10233B),
    textSecondary: Color(0xFF5D7088),
    textTertiary: Color(0xFF8090A6),
    primary: AppColors.primary,
    primarySoft: Color(0xFF4FA38C),
    primaryTint: Color(0xFFDCEFEA),
    gold: Color(0xFFB98B41),
    goldSoft: AppColors.goldSoft,
    goldTint: Color(0xFFF4E8D4),
    success: Color(0xFF3A925E),
    warning: Color(0xFFC5842E),
    error: Color(0xFFC45353),
    info: Color(0xFF3E83D7),
    white: AppColors.white,
    black: AppColors.black,
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? AppPalette.dark;
  }

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceStrong,
    Color? border,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? primary,
    Color? primarySoft,
    Color? primaryTint,
    Color? gold,
    Color? goldSoft,
    Color? goldTint,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? white,
    Color? black,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceStrong: surfaceStrong ?? this.surfaceStrong,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryTint: primaryTint ?? this.primaryTint,
      gold: gold ?? this.gold,
      goldSoft: goldSoft ?? this.goldSoft,
      goldTint: goldTint ?? this.goldTint,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      white: white ?? this.white,
      black: black ?? this.black,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }

    return AppPalette(
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceRaised:
          Color.lerp(surfaceRaised, other.surfaceRaised, t) ?? surfaceRaised,
      surfaceStrong:
          Color.lerp(surfaceStrong, other.surfaceStrong, t) ?? surfaceStrong,
      border: Color.lerp(border, other.border, t) ?? border,
      borderSubtle:
          Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textTertiary:
          Color.lerp(textTertiary, other.textTertiary, t) ?? textTertiary,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t) ?? primarySoft,
      primaryTint: Color.lerp(primaryTint, other.primaryTint, t) ?? primaryTint,
      gold: Color.lerp(gold, other.gold, t) ?? gold,
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t) ?? goldSoft,
      goldTint: Color.lerp(goldTint, other.goldTint, t) ?? goldTint,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      error: Color.lerp(error, other.error, t) ?? error,
      info: Color.lerp(info, other.info, t) ?? info,
      white: Color.lerp(white, other.white, t) ?? white,
      black: Color.lerp(black, other.black, t) ?? black,
    );
  }
}

abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double section = 40;
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 30;
  static const double full = 999;
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 420);
}

abstract final class AppShadows {
  static const List<BoxShadow> panel = <BoxShadow>[
    BoxShadow(
      color: Color(0x22000000),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> glow = <BoxShadow>[
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];
}
