import 'package:flutter/material.dart';
import 'package:frontend/src/core/design_tokens.dart';
import 'package:frontend/src/core/prayer_phase_style.dart';

class NextPrayerHero extends StatelessWidget {
  const NextPrayerHero({
    super.key,
    required this.phaseStyle,
    required this.loading,
    this.prayerLabel,
    this.timeLabel,
    this.countdownLabel,
  });

  final PrayerPhaseStyle phaseStyle;
  final bool loading;
  final String? prayerLabel;
  final String? timeLabel;
  final String? countdownLabel;

  @override
  Widget build(BuildContext context) {
    final bool hasContent = prayerLabel != null && timeLabel != null;
    final AppPalette palette = AppPalette.of(context);

    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: phaseStyle.heroGradient(palette),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.overlay(phaseStyle.accent, palette.border, 0.34),
        ),
        boxShadow: AppShadows.glow,
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -18,
            right: -10,
            child: _HeroOrb(
              color: phaseStyle.ambient,
              size: 138,
            ),
          ),
          Positioned(
            bottom: -24,
            left: -14,
            child: _HeroOrb(
              color: phaseStyle.ambientSoft,
              size: 118,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: loading
                ? const _HeroLoading()
                : hasContent
                    ? _HeroContent(
                        phaseStyle: phaseStyle,
                        prayerLabel: prayerLabel!,
                        timeLabel: timeLabel!,
                        countdownLabel: countdownLabel,
                      )
                    : const _HeroEmpty(),
          ),
        ],
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.phaseStyle,
    required this.prayerLabel,
    required this.timeLabel,
    required this.countdownLabel,
  });

  final PrayerPhaseStyle phaseStyle;
  final String prayerLabel;
  final String timeLabel;
  final String? countdownLabel;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Semantics(
      label: countdownLabel == null
          ? 'Nächstes Gebet $prayerLabel um $timeLabel'
          : 'Nächstes Gebet $prayerLabel um $timeLabel, verbleibend $countdownLabel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.overlay(
                AppColors.gold,
                palette.surfaceStrong,
                0.18,
              ),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: palette.goldSoft.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              'NÄCHSTES GEBET',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.gold,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      prayerLabel,
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: palette.textPrimary,
                                fontWeight: FontWeight.w700,
                                height: 0.95,
                              ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      timeLabel,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: palette.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              if (countdownLabel != null)
                _CountdownBadge(
                  label: countdownLabel!,
                  accent: phaseStyle.countdownAccent,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.overlay(accent, palette.surfaceStrong, 0.16),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'verbleibend',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.textTertiary,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeroLoading extends StatelessWidget {
  const _HeroLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 148,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: AppColors.primarySoft,
        ),
      ),
    );
  }
}

class _HeroEmpty extends StatelessWidget {
  const _HeroEmpty();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Row(
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: palette.surfaceStrong,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.cloud_off_rounded,
            color: palette.textTertiary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            'Keine Gebetszeiten verfügbar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: palette.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}

class _HeroOrb extends StatelessWidget {
  const _HeroOrb({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.02),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
