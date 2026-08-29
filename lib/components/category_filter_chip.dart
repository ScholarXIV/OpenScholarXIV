import 'package:arxiv/theme/app_theme.dart';
import 'package:flutter/material.dart';

class CategoryFilterChip extends StatelessWidget {
  const CategoryFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.semanticsLabel,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = selected
        ? colorScheme.primaryContainer
        : subtleSurfaceColor(colorScheme);
    final borderColor = selected
        ? colorScheme.primary.withValues(alpha: 0.45)
        : colorScheme.outlineVariant.withValues(alpha: 0.7);
    final foregroundColor = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel ?? label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: borderColor),
          ),
          child: subtitle == null
              ? Text(
                  label,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 12.5,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: foregroundColor.withValues(alpha: 0.75),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
