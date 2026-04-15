import 'package:flutter/material.dart';
import 'package:frontend/src/core/design_tokens.dart';
import 'package:frontend/src/core/prayer_phase_style.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    super.key,
    required this.phaseStyle,
    required this.refreshing,
    required this.onRefresh,
  });

  final PrayerPhaseStyle phaseStyle;
  final bool refreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.overlay(
                phaseStyle.accent,
                AppColors.surfaceRaised,
                0.14,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: phaseStyle.accent.withValues(alpha: 0.24),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.explore_rounded,
              size: 19,
              color: phaseStyle.accentSoft,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Salah Navigator',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 19,
                    letterSpacing: -0.2,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          IconButton(
            onPressed: refreshing ? null : onRefresh,
            tooltip: 'Aktualisieren',
            style: IconButton.styleFrom(
              minimumSize: const Size(40, 40),
              maximumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.surfaceRaised,
              side: BorderSide(
                color: phaseStyle.accent.withValues(alpha: 0.16),
              ),
            ),
            icon: AnimatedRotation(
              duration: AppMotion.medium,
              turns: refreshing ? 1 : 0,
              child: const Icon(Icons.refresh_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
