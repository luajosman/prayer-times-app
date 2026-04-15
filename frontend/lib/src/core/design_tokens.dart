import 'package:flutter/material.dart';

/// Centralized design tokens for Salah Navigator.
/// All color, spacing, and shape values are sourced from here.
abstract final class AppColors {
  // ── Backgrounds ─────────────────────────────────────────────────────────────
  static const Color background  = Color(0xFF0F172A);
  static const Color surface     = Color(0xFF162033);
  static const Color surfaceHigh = Color(0xFF1E293B);

  // ── Brand ────────────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF2E8B75);
  static const Color primaryLight = Color(0xFF56B39D);
  static const Color gold         = Color(0xFFD4A95A);
  static const Color goldLight    = Color(0xFFE8C47A);

  // ── Text ─────────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFB6C2D1);
  static const Color textTertiary  = Color(0xFF6B7E94);

  // ── Structural ───────────────────────────────────────────────────────────────
  static const Color border       = Color(0xFF2B3950);
  static const Color borderSubtle = Color(0xFF1E2E42);

  // ── Semantic ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF3FAE6A);
  static const Color warning = Color(0xFFE6A23C);
  static const Color error   = Color(0xFFD95C5C);
  static const Color info    = Color(0xFF5DADE2);
}

abstract final class AppSpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
}

abstract final class AppRadius {
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xxl  = 28.0;
  static const double full = 999.0;
}
