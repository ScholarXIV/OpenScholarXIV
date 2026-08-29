import 'package:arxiv/components/app_bottom_sheet.dart';
import 'package:arxiv/components/category_filter_chip.dart';
import 'package:arxiv/data/arxiv_categories.dart';
import 'package:arxiv/services/arxiv_category_parser.dart';
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
      maxHeightFactor: 0.72,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 20.0),
        children: [
          for (final entry in groupedCategories.entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: entry.value.map((category) {
                return CategoryFilterChip(
                  label: categoryChipLabel(category),
                  subtitle: category.code,
                  selected: isCategorySelected(category, currentQuery),
                  onTap: () => onCategorySelected(category),
                );
              }).toList(),
            ),
            const SizedBox(height: 14.0),
          ],
        ],
      ),
    );
  }
}
