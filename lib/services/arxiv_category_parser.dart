import 'package:arxiv/data/arxiv_categories.dart';

final _categoryQueryPattern = RegExp(r'^cat:([^\s]+)$', caseSensitive: false);

List<ArxivCategory> featuredArxivCategories() {
  return featuredArxivCategoryCodes
      .map(categoryByCode)
      .whereType<ArxivCategory>()
      .toList(growable: false);
}

bool isCategoryQuery(String query) {
  return categoryCodeFromQuery(query) != null;
}

String? categoryCodeFromQuery(String query) {
  final match = _categoryQueryPattern.firstMatch(query.trim());
  final code = match?.group(1)?.trim();

  if (code == null || code.isEmpty) return null;
  return code;
}

// casse-insensitive look up of category by a given code
ArxivCategory? categoryByCode(String code) {
  final normalizedCode = code.trim().toLowerCase();
  for (final category in arxivCategories) {
    if (category.code.toLowerCase() == normalizedCode) return category;
  }
  return null;
}

ArxivCategory? categoryForQuery(String query) {
  final code = categoryCodeFromQuery(query);
  if (code == null) return null;

  return categoryByCode(code);
}

ArxivCategory? categoryForFilterLabel(String label) {
  final normalizedLabel = label.trim();
  if (normalizedLabel.isEmpty) return null;

  for (final category in arxivCategories) {
    if (categoryFilterLabel(category) == normalizedLabel) {
      return category;
    }
  }
  return null;
}

ArxivCategory? categoryFromSearchInput(String input) {
  return categoryForQuery(input) ?? categoryForFilterLabel(input);
}

String effectiveSearchQuery(String input) {
  final category = categoryFromSearchInput(input);
  if (category != null) {
    return category.query;
  }
  return input.trim();
}

List<ArxivCategory> visibleFilterCategories(String currentQuery) {
  final featured = featuredArxivCategories();
  final activeCategory = categoryFromSearchInput(currentQuery);
  if (activeCategory == null) {
    return featured;
  }

  final remaining = featured
      .where((category) => category.code != activeCategory.code)
      .toList();
  return [activeCategory, ...remaining];
}

Map<String, List<ArxivCategory>> groupedArxivCategories() {
  final groups = <String, List<ArxivCategory>>{};
  for (final category in arxivCategories) {
    groups.putIfAbsent(category.group, () => []).add(category);
  }
  return groups;
}

bool isCategorySelected(ArxivCategory category, String currentQuery) {
  final activeCategory = categoryFromSearchInput(currentQuery);
  return activeCategory?.code == category.code;
}

void handleCategoryChipTap({
  required ArxivCategory category,
  required String currentQuery,
  required void Function(ArxivCategory category) onCategorySelected,
  required void Function() onClearCategory,
}) {
  if (isCategorySelected(category, currentQuery)) {
    onClearCategory();
    return;
  }
  onCategorySelected(category);
}

String categoryChipLabel(ArxivCategory category) => category.label;
String categoryFilterLabel(ArxivCategory category) =>
    "${category.code} - ${category.label}";
