import 'package:flutter/material.dart';
import 'package:frontend/src/core/design_tokens.dart';
import 'package:frontend/src/core/prayer_phase_style.dart';
import 'package:frontend/src/ui/widgets/context_chip.dart';

class TrustContextStrip extends StatelessWidget {
  const TrustContextStrip({
    super.key,
    required this.location,
    required this.timezone,
    required this.methodLabel,
    required this.schoolLabel,
    required this.phaseStyle,
  });

  final String location;
  final String? timezone;
  final String methodLabel;
  final String schoolLabel;
  final PrayerPhaseStyle phaseStyle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        ContextChip(
          icon: Icons.place_outlined,
          label: location,
          compact: true,
        ),
        if (timezone != null && timezone!.trim().isNotEmpty)
          ContextChip(
            icon: Icons.public_rounded,
            label: timezone!,
            compact: true,
          ),
        ContextChip(
          icon: Icons.tune_rounded,
          label: methodLabel,
          compact: true,
        ),
        ContextChip(
          icon: Icons.school_outlined,
          label: schoolLabel,
          compact: true,
          accentColor: phaseStyle.emphasisColor(palette),
        ),
      ],
    );
  }
}
