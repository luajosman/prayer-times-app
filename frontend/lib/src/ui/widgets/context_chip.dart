import 'package:flutter/material.dart';
import 'package:frontend/src/core/design_tokens.dart';

class ContextChip extends StatelessWidget {
  const ContextChip({
    super.key,
    required this.icon,
    required this.label,
    this.accentColor = AppColors.primarySoft,
    this.emphasized = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final bool emphasized;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color background = emphasized
        ? AppColors.overlay(accentColor, AppColors.surfaceRaised, 0.12)
        : AppColors.surfaceRaised;
    final Color borderColor =
        emphasized ? accentColor.withValues(alpha: 0.28) : AppColors.border;
    final Color iconColor = emphasized ? accentColor : AppColors.primarySoft;
    final Color textColor =
        emphasized ? AppColors.textPrimary : const Color(0xFFB7C3D3);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 280 : 340),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: compact ? 6 : AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: compact ? 12 : 14, color: iconColor),
            SizedBox(width: compact ? 6 : AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: textColor,
                      fontWeight:
                          emphasized ? FontWeight.w600 : FontWeight.w500,
                      fontSize: compact ? 11 : 12,
                      height: 1.0,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
