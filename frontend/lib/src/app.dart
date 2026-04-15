import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/src/ui/prayer_home_page.dart';

class PrayerTimesApp extends StatelessWidget {
  const PrayerTimesApp({super.key, this.autoLoad = true});

  final bool autoLoad;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salah Navigator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: PrayerHomePage(autoLoad: autoLoad),
    );
  }
}
