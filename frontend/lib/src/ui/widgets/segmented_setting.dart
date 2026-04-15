import 'package:flutter/material.dart';
import 'package:frontend/src/core/design_tokens.dart';

class SegmentedSettingOption<T> {
  const SegmentedSettingOption({
    required this.value,
    required this.label,
    this.semanticLabel,
  });

  final T value;
  final String label;
  final String? semanticLabel;
}

class SegmentedSetting<T> extends StatelessWidget {
  const SegmentedSetting({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.accentColor,
  });

  final T value;
  final List<SegmentedSettingOption<T>> options;
  final ValueChanged<T> onChanged;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color resolvedAccent = accentColor ?? palette.primarySoft;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: palette.surfaceStrong,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Row(
        children: <Widget>[
          for (int index = 0; index < options.length; index++) ...<Widget>[
            Expanded(
              child: _SegmentItem<T>(
                option: options[index],
                selected: options[index].value == value,
                accentColor: resolvedAccent,
                onPressed: () => onChanged(options[index].value),
              ),
            ),
            if (index < options.length - 1)
              const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _SegmentItem<T> extends StatelessWidget {
  const _SegmentItem({
    required this.option,
    required this.selected,
    required this.accentColor,
    required this.onPressed,
  });

  final SegmentedSettingOption<T> option;
  final bool selected;
  final Color accentColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: option.semanticLabel ?? option.label,
      child: InkWell(
        onTap: selected ? null : onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.overlay(accentColor, palette.surfaceRaised, 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected
                  ? accentColor.withValues(alpha: 0.32)
                  : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            option.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? accentColor : palette.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  height: 1.1,
                ),
          ),
        ),
      ),
    );
  }
}
