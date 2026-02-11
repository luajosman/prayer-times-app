import 'package:flutter/material.dart';
import 'package:frontend/src/ui/prayer_home_page.dart';

class PrayerTimesApp extends StatelessWidget {
  const PrayerTimesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E8D92),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF64E0D6),
      secondary: const Color(0xFFFFD166),
      surface: const Color(0xFF1D2637),
    );

    final TextTheme base = Typography.whiteMountainView;

    return MaterialApp(
      title: 'Prayer Compass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF111826),
        textTheme: base.copyWith(
          headlineMedium: base.headlineMedium?.copyWith(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontFamily: 'Georgia',
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontFamily: 'Georgia',
            color: Colors.white.withOpacity(0.84),
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withOpacity(0.06),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.16)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.16)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF64E0D6), width: 1.2),
          ),
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.78)),
        ),
      ),
      home: const PrayerHomePage(),
    );
  }
}
