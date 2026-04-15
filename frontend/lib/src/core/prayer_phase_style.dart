import 'package:flutter/material.dart';
import 'package:frontend/src/core/design_tokens.dart';

enum PrayerPhase {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
}

class PrayerPhaseStyle {
  const PrayerPhaseStyle({
    required this.phase,
    required this.label,
    required this.accent,
    required this.accentSoft,
    required this.tint,
    required this.ambient,
    required this.ambientSoft,
    required this.countdownAccent,
    required this.sectionAccent,
    required this.qiblaAmbient,
  });

  final PrayerPhase phase;
  final String label;
  final Color accent;
  final Color accentSoft;
  final Color tint;
  final Color ambient;
  final Color ambientSoft;
  final Color countdownAccent;
  final Color sectionAccent;
  final Color qiblaAmbient;

  LinearGradient heroGradient(AppPalette palette) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        AppColors.overlay(ambient, palette.surface, 0.18),
        AppColors.overlay(tint, palette.surfaceRaised, 0.68),
      ],
    );
  }
}

PrayerPhaseStyle prayerPhaseStyleOf(PrayerPhase phase) {
  return switch (phase) {
    PrayerPhase.fajr => const PrayerPhaseStyle(
        phase: PrayerPhase.fajr,
        label: 'Fajr',
        accent: Color(0xFF4E91A5),
        accentSoft: Color(0xFF82C1CF),
        tint: Color(0xFF112B39),
        ambient: Color(0xFF21495F),
        ambientSoft: Color(0xFF2D6076),
        countdownAccent: Color(0xFF9FD1DD),
        sectionAccent: Color(0xFF7AB8C7),
        qiblaAmbient: Color(0xFF1B3348),
      ),
    PrayerPhase.sunrise => const PrayerPhaseStyle(
        phase: PrayerPhase.sunrise,
        label: 'Sunrise',
        accent: Color(0xFFB38B5E),
        accentSoft: Color(0xFFD4B181),
        tint: Color(0xFF2A2117),
        ambient: Color(0xFF4D3820),
        ambientSoft: Color(0xFF6C4B29),
        countdownAccent: Color(0xFFC9A46F),
        sectionAccent: Color(0xFFB49062),
        qiblaAmbient: Color(0xFF302618),
      ),
    PrayerPhase.dhuhr => const PrayerPhaseStyle(
        phase: PrayerPhase.dhuhr,
        label: 'Dhuhr',
        accent: AppColors.primary,
        accentSoft: AppColors.primarySoft,
        tint: AppColors.primaryTint,
        ambient: Color(0xFF1C4A41),
        ambientSoft: Color(0xFF285C50),
        countdownAccent: AppColors.primarySoft,
        sectionAccent: AppColors.primarySoft,
        qiblaAmbient: Color(0xFF1F3148),
      ),
    PrayerPhase.asr => const PrayerPhaseStyle(
        phase: PrayerPhase.asr,
        label: 'Asr',
        accent: Color(0xFF4A9A84),
        accentSoft: Color(0xFF79BDA7),
        tint: Color(0xFF19392F),
        ambient: Color(0xFF294C43),
        ambientSoft: Color(0xFF365E53),
        countdownAccent: Color(0xFF8AC7B3),
        sectionAccent: Color(0xFF6CA894),
        qiblaAmbient: Color(0xFF25354B),
      ),
    PrayerPhase.maghrib => const PrayerPhaseStyle(
        phase: PrayerPhase.maghrib,
        label: 'Maghrib',
        accent: Color(0xFFC79246),
        accentSoft: Color(0xFFE4BC77),
        tint: AppColors.goldTint,
        ambient: Color(0xFF5A3D21),
        ambientSoft: Color(0xFF7A5027),
        countdownAccent: AppColors.gold,
        sectionAccent: AppColors.gold,
        qiblaAmbient: Color(0xFF392B1D),
      ),
    PrayerPhase.isha => const PrayerPhaseStyle(
        phase: PrayerPhase.isha,
        label: 'Isha',
        accent: Color(0xFF7182BC),
        accentSoft: Color(0xFFA7B2DA),
        tint: Color(0xFF18243B),
        ambient: Color(0xFF273456),
        ambientSoft: Color(0xFF33426B),
        countdownAccent: Color(0xFFB6C0E6),
        sectionAccent: Color(0xFF8494CA),
        qiblaAmbient: Color(0xFF202D47),
      ),
  };
}
