// ignore_for_file: file_names
import 'package:arxiv/components/category_picker_sheet.dart';
import 'package:arxiv/data/arxiv_categories.dart';
import 'package:arxiv/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SearchBox extends StatelessWidget {
  const SearchBox({
    super.key,
    required this.searchTermController,
    required this.searchFunction,
    required this.toggleSortOrder,
    required this.sortOrderNewest,
    required this.onCategorySelected,
  });

  final TextEditingController searchTermController;
  final Future<void> Function({bool? resetPagination}) searchFunction;
  final Future<void> Function() toggleSortOrder;
  final bool sortOrderNewest;
  final ValueChanged<ArxivCategory> onCategorySelected;

  void clearSearchQuery() {
    searchTermController.clear();
    // Empty input reloads suggested papers instead of running a blank search.
    searchFunction(resetPagination: true);
  }

  void openCategoryPicker(BuildContext context) {
    showCategoryPickerSheet(
      context,
      currentQuery: searchTermController.text.trim(),
      onCategorySelected: onCategorySelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(color: colorScheme.surface),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 18.0, right: 18.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0),
                color: subtleSurfaceColor(colorScheme),
              ),
              child: TextField(
                controller: searchTermController,
                keyboardType: TextInputType.url,
                cursorColor: colorScheme.primary,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: "Search...",
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                  suffixIcon: searchTermController.text.isNotEmpty
                      ? IconButton(
                          onPressed: clearSearchQuery,
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                ),
                onSubmitted: (searchTerm) {
                  searchFunction(resetPagination: true);
                },
              ),
            ),
          ),
          IconButton(
            tooltip: "Browse categories",
            onPressed: () => openCategoryPicker(context),
            icon: const Icon(Icons.category_outlined),
          ),
          IconButton(
            onPressed: () => toggleSortOrder(),
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            onPressed: () {
              searchFunction(resetPagination: true);
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }
}
