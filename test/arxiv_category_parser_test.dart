import 'package:arxiv/data/arxiv_categories.dart';
import 'package:arxiv/services/arxiv_category_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('categoryCodeFromQuery', () {
    test('extracts the code from a category query', () {
      expect(categoryCodeFromQuery('cat:cs.LG'), 'cs.LG');
    });

    test('is case-insensitive on the cat prefix', () {
      expect(categoryCodeFromQuery('CAT:cs.AI'), 'cs.AI');
    });

    test('trims surrounding whitespace', () {
      expect(categoryCodeFromQuery('  cat:quant-ph  '), 'quant-ph');
    });

    test('returns null for free-text and field queries', () {
      expect(categoryCodeFromQuery('transformer'), isNull);
      expect(categoryCodeFromQuery('all:transformer'), isNull);
      expect(categoryCodeFromQuery('au:"Alan Turing"'), isNull);
    });

    test('returns null for compound or partial category queries', () {
      expect(
        categoryCodeFromQuery('cat:cs.LG AND all:transformer'),
        isNull,
      );
      expect(categoryCodeFromQuery('cat:'), isNull);
      expect(categoryCodeFromQuery(''), isNull);
    });
  });

  group('isCategoryQuery', () {
    test('is true only for exact category filters', () {
      expect(isCategoryQuery('cat:cs.LG'), isTrue);
      expect(isCategoryQuery('cat:quant-ph'), isTrue);
    });

    test('is false for everything else', () {
      expect(isCategoryQuery('transformer'), isFalse);
      expect(isCategoryQuery('cat:cs.LG AND all:bert'), isFalse);
      expect(isCategoryQuery(''), isFalse);
    });
  });

  group('categoryByCode', () {
    test('finds a known category regardless of casing', () {
      final category = categoryByCode('CS.LG');

      expect(category, isNotNull);
      expect(category!.code, 'cs.LG');
      expect(category.label, 'Machine Learning');
      expect(category.group, 'Computer Science');
    });

    test('returns null for unknown codes', () {
      expect(categoryByCode('cs.XX'), isNull);
      expect(categoryByCode(''), isNull);
    });
  });

  group('categoryForQuery', () {
    test('resolves a category query to its ArxivCategory', () {
      final category = categoryForQuery('cat:cs.AI');

      expect(category, isNotNull);
      expect(category!.code, 'cs.AI');
      expect(category.label, 'Artificial Intelligence');
    });

    test('returns null when the query is not a category filter', () {
      expect(categoryForQuery('transformer'), isNull);
      expect(categoryForQuery('all:neural networks'), isNull);
    });

    test('returns null when the category code is not in the catalog', () {
      expect(categoryForQuery('cat:cs.XX'), isNull);
    });
  });

  group('category labels', () {
    const category = ArxivCategory(
      code: 'cs.LG',
      label: 'Machine Learning',
      group: 'Computer Science',
    );

    test('categoryChipLabel uses the short code', () {
      expect(categoryChipLabel(category), 'cs.LG');
    });

    test('categoryFilterLabel combines code and human label', () {
      expect(categoryFilterLabel(category), 'cs.LG - Machine Learning');
    });
  });
}
