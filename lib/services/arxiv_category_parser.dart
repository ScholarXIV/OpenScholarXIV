import 'package:arxiv/data/arxiv_categories.dart';

final _categoryQueryPattern = RegExp(r'^cat:([^\s]+)$', caseSensitive: false);

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

String categoryChipLabel(ArxivCategory category) => category.code;
String categoryFilterLabel(ArxivCategory category) =>
    "${category.code} - ${category.label}";
