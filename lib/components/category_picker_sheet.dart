import 'package:arxiv/components/app_bottom_sheet.dart';
import 'package:arxiv/data/arxiv_categories.dart';
import 'package:arxiv/services/arxiv_category_parser.dart';
import 'package:arxiv/theme/app_theme.dart';
import 'package:flutter/material.dart';

Future<void> showCategoryPickerSheet(
  BuildContext context, {
  required String currentQuery,
  required ValueChanged<ArxivCategory> onCategorySelected,
}) {
  return showAppBottomSheet<void>(
    context,
    child: Builder(
      builder: (sheetContext) {
        return CategoryPickerSheet(
          currentQuery: currentQuery,
          onCategorySelected: (category) {
            // Close the sheet before triggering search so the feed updates underneath.
            Navigator.pop(sheetContext);
            onCategorySelected(category);
          },
        );
      },
    ),
  );
}

class CategoryPickerSheet extends StatelessWidget {
  const CategoryPickerSheet({
    super.key,
    required this.currentQuery,
    required this.onCategorySelected,
  });

  final String currentQuery;
  final ValueChanged<ArxivCategory> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final groupedCategories = groupedArxivCategories();

    return AppBottomSheetShell(
      title: "Categories",
      maxHeightFactor: 0.76,
      titleTextStyle: TextStyle(
        fontSize: 21.0,
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
        height: 1.2,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 24.0),
        children: [
          for (final entry in groupedCategories.entries)
            Padding(
              padding: const EdgeInsets.only(top: 14.0),
              child: _CategorySectionGroup(
                title: entry.key,
                children: [
                  for (final category in entry.value)
                    _CategoryPickerRow(
                      category: category,
                      selected: isCategorySelected(category, currentQuery),
                      onTap: () => onCategorySelected(category),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CategorySectionGroup extends StatelessWidget {
  const _CategorySectionGroup({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: subtleSurfaceColor(colorScheme),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    height: 1.2,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8.0),
                Divider(
                  height: 1.0,
                  thickness: 1.0,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6.0),
          Padding(
            padding: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPickerRow extends StatelessWidget {
  const _CategoryPickerRow({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ArxivCategory category;
  final bool selected;
  final VoidCallback onTap;

  static const _rowRadius = 10.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      // Codes are hidden in the UI but exposed to screen readers.
      label: '${category.label}, ${category.code}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.62)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(_rowRadius),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(_rowRadius),
              splashColor: colorScheme.primary.withValues(alpha: 0.08),
              highlightColor: colorScheme.primary.withValues(alpha: 0.04),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 11.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 14.5,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  height: 1.25,
                                  color: selected
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurface,
                                ) ??
                            const TextStyle(),
                        child: Text(categoryChipLabel(category)),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    AnimatedScale(
                      scale: selected ? 1.0 : 0.85,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: selected ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 180),
                        child: Container(
                          width: 22.0,
                          height: 22.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 14.0,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
