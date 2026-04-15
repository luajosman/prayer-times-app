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
