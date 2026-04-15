import 'package:flutter/material.dart';
import 'package:frontend/src/core/design_tokens.dart';

class PrayerTimeTile extends StatelessWidget {
  const PrayerTimeTile({
    super.key,
    required this.prayerKey,
    required this.title,
    required this.time,
    required this.isNext,
  });

  final String prayerKey;
  final String title;
  final String time;
  final bool isNext;

  bool get _isSunrise => prayerKey == 'Sunrise';

  @override
  Widget build(BuildContext context) {
    if (_isSunrise) return _SunriseTile(title: title, time: time);
    if (isNext) return _NextTile(prayerKey: prayerKey, title: title, time: time);
    return _DefaultTile(prayerKey: prayerKey, title: title, time: time);
  }
}

// ── Default prayer tile ───────────────────────────────────────────────────────

class _DefaultTile extends StatelessWidget {
  const _DefaultTile({
    required this.prayerKey,
    required this.title,
    required this.time,
  });

  final String prayerKey;
  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          _PrayerIconBox(prayerKey: prayerKey, isNext: false),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Next prayer tile — gold accent ────────────────────────────────────────────

class _NextTile extends StatelessWidget {
  const _NextTile({
    required this.prayerKey,
    required this.title,
    required this.time,
  });

  final String prayerKey;
  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AppColors.gold.withValues(alpha: 0.09),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: <Widget>[
          _PrayerIconBox(prayerKey: prayerKey, isNext: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Nächstes Gebet',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.gold.withValues(alpha: 0.65),
                        letterSpacing: 0.5,
                      ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Sunrise tile — de-emphasised, non-prayer marker ──────────────────────────

class _SunriseTile extends StatelessWidget {
  const _SunriseTile({required this.title, required this.time});

  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AppColors.surfaceHigh.withValues(alpha: 0.45),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.wb_sunny_outlined,
              size: 15,
              color: AppColors.warning.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Prayer icon box ───────────────────────────────────────────────────────────

class _PrayerIconBox extends StatelessWidget {
  const _PrayerIconBox({required this.prayerKey, required this.isNext});

  final String prayerKey;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isNext
            ? AppColors.gold.withValues(alpha: 0.88)
            : AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
      ),
      alignment: Alignment.center,
      child: Icon(
        _iconFor(prayerKey),
        size: 17,
        color: isNext ? const Color(0xFF2A1F08) : AppColors.primaryLight,
      ),
    );
  }

  static IconData _iconFor(String key) {
    return switch (key) {
      'Fajr'    => Icons.wb_twilight_rounded,
      'Dhuhr'   => Icons.light_mode_rounded,
      'Asr'     => Icons.filter_drama_rounded,
      'Maghrib' => Icons.nights_stay_rounded,
      'Isha'    => Icons.dark_mode_rounded,
      _         => Icons.schedule_rounded,
    };
  }
}
