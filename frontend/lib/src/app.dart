import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/src/core/app_theme_preference.dart';
import 'package:frontend/src/core/prayer_phase_resolver.dart';
import 'package:frontend/src/core/prayer_phase_style.dart';
import 'package:frontend/src/services/settings_store.dart';
import 'package:frontend/src/ui/prayer_home_page.dart';

class PrayerTimesApp extends StatefulWidget {
  const PrayerTimesApp({super.key, this.autoLoad = true});

  final bool autoLoad;

  @override
  State<PrayerTimesApp> createState() => _PrayerTimesAppState();
}

class _PrayerTimesAppState extends State<PrayerTimesApp> {
  final SettingsStore _settingsStore = SettingsStore();

  AppThemePreference _themePreference = AppThemePreference.prayerBased;
  PrayerPhase _prayerPhase = fallbackPrayerPhaseFor(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final settings = await _settingsStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _themePreference = settings.themePreference;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salah Navigator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themePreference.resolveThemeMode(_prayerPhase),
      themeAnimationDuration: const Duration(milliseconds: 320),
      themeAnimationCurve: Curves.easeOutCubic,
      home: PrayerHomePage(
        autoLoad: widget.autoLoad,
        onThemeModeChanged: _handleThemePreferenceChanged,
        onPrayerPhaseChanged: _handlePrayerPhaseChanged,
      ),
    );
  }

  void _handleThemePreferenceChanged(AppThemePreference preference) {
    if (_themePreference == preference) {
      return;
    }
    setState(() {
      _themePreference = preference;
    });
  }

  void _handlePrayerPhaseChanged(PrayerPhase phase) {
    if (_prayerPhase == phase) {
      return;
    }
    setState(() {
      _prayerPhase = phase;
    });
  }
}
