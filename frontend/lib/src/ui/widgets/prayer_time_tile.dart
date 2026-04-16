import 'package:flutter/material.dart';
import 'package:frontend/src/core/design_tokens.dart';
import 'package:frontend/src/core/prayer_phase_style.dart';

class PrayerTimeTile extends StatelessWidget {
  const PrayerTimeTile({
    super.key,
    required this.prayerKey,
    required this.title,
    required this.time,
    required this.isNext,
    required this.phaseStyle,
  });

  final String prayerKey;
  final String title;
  final String time;
  final bool isNext;
  final PrayerPhaseStyle phaseStyle;

  bool get _isSunrise => prayerKey == 'Sunrise';

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    if (_isSunrise) {
      return _PrayerTileShell(
        prayerKey: prayerKey,
        title: title,
        time: time,
        subtitle: 'Übergang',
        backgroundColor: AppColors.overlay(
          const Color(0xFFB68C58),
          palette.surface,
          palette.isDark ? 0.08 : 0.06,
        ),
        borderColor: palette.borderSubtle,
        titleColor: palette.textSecondary,
        subtitleColor: palette.textTertiary,
        timeColor: palette.textSecondary,
        iconTileColor: AppColors.overlay(
          const Color(0xFFB68C58),
          palette.surfaceStrong,
          0.12,
        ),
        iconColor: const Color(0xFFD0A56A),
      );
    }

    if (isNext) {
      return _PrayerTileShell(
        prayerKey: prayerKey,
        title: title,
        time: time,
        subtitle: 'Nächstes Gebet',
        backgroundColor: phaseStyle.nextPrayerBackground(palette),
        borderColor: phaseStyle.nextPrayerBorder(palette),
        titleColor: palette.textPrimary,
        subtitleColor: phaseStyle.emphasisColor(palette),
        timeColor: phaseStyle.countdownColor(palette),
        iconTileColor: phaseStyle.nextPrayerIconTile(palette),
        iconColor: phaseStyle.emphasisColor(palette),
      );
    }

    return _PrayerTileShell(
      prayerKey: prayerKey,
      title: title,
      time: time,
      backgroundColor: palette.surfaceRaised,
      borderColor: palette.border,
      titleColor: palette.textPrimary,
      subtitleColor: palette.textSecondary,
      timeColor: palette.textPrimary,
      iconTileColor: palette.surfaceStrong,
      iconColor: palette.primarySoft,
    );
  }
}

class _PrayerTileShell extends StatelessWidget {
  const _PrayerTileShell({
    required this.prayerKey,
    required this.title,
    required this.time,
    required this.backgroundColor,
    required this.borderColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.timeColor,
    required this.iconTileColor,
    required this.iconColor,
    this.subtitle,
  });

  final String prayerKey;
  final String title;
  final String time;
  final String? subtitle;
  final Color backgroundColor;
  final Color borderColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color timeColor;
  final Color iconTileColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconTileColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Icon(
              _iconFor(prayerKey),
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: titleColor,
                        fontSize: 17,
                      ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: subtitleColor,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            time,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: timeColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(String key) {
    return switch (key) {
      'Fajr' => Icons.wb_twilight_rounded,
      'Sunrise' => Icons.wb_sunny_outlined,
      'Dhuhr' => Icons.light_mode_rounded,
      'Asr' => Icons.filter_drama_rounded,
      'Maghrib' => Icons.nights_stay_rounded,
      'Isha' => Icons.dark_mode_rounded,
      _ => Icons.schedule_rounded,
    };
  }
}
