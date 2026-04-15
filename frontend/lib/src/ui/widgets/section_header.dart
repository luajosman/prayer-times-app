import 'package:flutter/material.dart';
import 'package:frontend/src/core/design_tokens.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.accentColor = AppColors.gold,
  });

  final String label;
  final String? trailing;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Row(
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: accentColor.withValues(alpha: 0.24),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: palette.textSecondary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
        ),
        const Spacer(),
        if (trailing != null && trailing!.trim().isNotEmpty)
          Text(
            trailing!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: palette.textTertiary,
                ),
          ),
      ],
    );
  }
}
