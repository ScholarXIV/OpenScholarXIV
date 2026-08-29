import 'package:arxiv/components/category_filter_chip.dart';
import 'package:arxiv/data/arxiv_categories.dart';
import 'package:arxiv/services/arxiv_category_parser.dart';
import 'package:flutter/material.dart';

class SearchFilterChips extends StatefulWidget {
  const SearchFilterChips({
    super.key,
    required this.currentQuery,
    required this.onCategorySelected,
    required this.onClearCategory,
  });

  final String currentQuery;
  final ValueChanged<ArxivCategory> onCategorySelected;
  final Future<void> Function() onClearCategory;

  @override
  State<SearchFilterChips> createState() => _SearchFilterChipsState();
}

class _SearchFilterChipsState extends State<SearchFilterChips> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(SearchFilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldActive = categoryFromSearchInput(oldWidget.currentQuery)?.code;
    final newActive = categoryFromSearchInput(widget.currentQuery)?.code;
    if (oldActive != newActive) {
      _scrollToStart();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filterCategories = visibleFilterCategories(widget.currentQuery);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Filter",
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6.0),
          SizedBox(
            height: 32.0,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: filterCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6.0),
              itemBuilder: (context, index) {
                final category = filterCategories[index];
                return CategoryFilterChip(
                  label: categoryChipLabel(category),
                  selected: isCategorySelected(category, widget.currentQuery),
                  onTap: () async {
                    await handleCategoryChipTap(
                      category: category,
                      currentQuery: widget.currentQuery,
                      onCategorySelected: widget.onCategorySelected,
                      onClearCategory: widget.onClearCategory,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
