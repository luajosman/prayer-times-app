import 'package:flutter/material.dart';
import 'package:frontend/src/core/prayer_phase_style.dart';

enum AppThemePreference {
  light,
  dark,
  prayerBased,
}

AppThemePreference appThemePreferenceFromStorage(String? raw) {
  return switch (raw) {
    'light' => AppThemePreference.light,
    'dark' => AppThemePreference.dark,
    'prayer_based' => AppThemePreference.prayerBased,
    _ => AppThemePreference.prayerBased,
  };
}

extension AppThemePreferenceX on AppThemePreference {
  String get storageValue {
    return switch (this) {
      AppThemePreference.light => 'light',
      AppThemePreference.dark => 'dark',
      AppThemePreference.prayerBased => 'prayer_based',
    };
  }

  ThemeMode resolveThemeMode(PrayerPhase phase) {
    return switch (this) {
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.dark => ThemeMode.dark,
      AppThemePreference.prayerBased =>
        prayerPhasePrefersDark(phase) ? ThemeMode.dark : ThemeMode.light,
    };
  }
}

bool prayerPhasePrefersDark(PrayerPhase phase) {
  return switch (phase) {
    PrayerPhase.fajr || PrayerPhase.maghrib || PrayerPhase.isha => true,
    PrayerPhase.sunrise || PrayerPhase.dhuhr || PrayerPhase.asr => false,
  };
}
