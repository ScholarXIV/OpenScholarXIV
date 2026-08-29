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

  group('featuredArxivCategories', () {
    test('resolves configured featured category codes', () {
      final featured = featuredArxivCategories();

      expect(featured, isNotEmpty);
      expect(
        featured.every(
          (category) => featuredArxivCategoryCodes.contains(category.code),
        ),
        isTrue,
      );
    });
  });

  group('categoryFromSearchInput', () {
    test('resolves category filter labels shown in the search field', () {
      final category = categoryFromSearchInput('cs.LG - Machine Learning');

      expect(category, isNotNull);
      expect(category!.code, 'cs.LG');
    });

    test('still resolves raw category queries', () {
      expect(categoryFromSearchInput('cat:cs.AI')?.code, 'cs.AI');
    });
  });

  group('effectiveSearchQuery', () {
    test('converts a filter label to an arXiv category query', () {
      expect(
        effectiveSearchQuery('cs.LG - Machine Learning'),
        'cat:cs.LG',
      );
    });

    test('passes through free-text searches unchanged', () {
      expect(effectiveSearchQuery('transformer'), 'transformer');
    });

    test('trims free-text searches without altering category filters', () {
      expect(effectiveSearchQuery('  transformer  '), 'transformer');
      expect(
        effectiveSearchQuery('  cs.LG - Machine Learning  '),
        'cat:cs.LG',
      );
    });

    test('returns empty string for blank input', () {
      expect(effectiveSearchQuery(''), '');
      expect(effectiveSearchQuery('   '), '');
    });
  });

  group('visibleFilterCategories', () {
    test('returns featured categories when no filter is active', () {
      final visible = visibleFilterCategories('');

      expect(visible.map((category) => category.code), featuredArxivCategories().map((category) => category.code));
    });

    test('puts the active category first even when it is not featured', () {
      final visible = visibleFilterCategories('stat.TH - Statistics Theory');

      expect(visible.first.code, 'stat.TH');
      expect(visible.skip(1).map((category) => category.code), featuredArxivCategories().map((category) => category.code));
    });

    test('moves an active featured category to the front', () {
      final visible = visibleFilterCategories('cs.LG - Machine Learning');

      expect(visible.first.code, 'cs.LG');
      expect(visible.where((category) => category.code == 'cs.LG').length, 1);
    });
  });

  group('groupedArxivCategories', () {
    test('groups categories by their subject area', () {
      final grouped = groupedArxivCategories();

      expect(grouped['Computer Science'], isNotEmpty);
      expect(
        grouped['Computer Science']!.any((category) => category.code == 'cs.AI'),
        isTrue,
      );
    });
  });

  group('isCategorySelected', () {
    test('matches both category query and filter label input', () {
      const category = ArxivCategory(
        code: 'cs.LG',
        label: 'Machine Learning',
        group: 'Computer Science',
      );

      expect(isCategorySelected(category, 'cat:cs.LG'), isTrue);
      expect(isCategorySelected(category, 'cs.LG - Machine Learning'), isTrue);
      expect(isCategorySelected(category, 'transformer'), isFalse);
    });
  });

  group('handleCategoryChipTap', () {
    const category = ArxivCategory(
      code: 'cs.LG',
      label: 'Machine Learning',
      group: 'Computer Science',
    );

    test('selects a category when it is not active', () async {
      ArxivCategory? selected;
      var cleared = false;

      await handleCategoryChipTap(
        category: category,
        currentQuery: '',
        onCategorySelected: (value) => selected = value,
        onClearCategory: () async => cleared = true,
      );

      expect(selected, category);
      expect(cleared, isFalse);
    });

    test('clears the filter when tapping the active category', () async {
      ArxivCategory? selected;
      var cleared = false;

      await handleCategoryChipTap(
        category: category,
        currentQuery: 'cs.LG - Machine Learning',
        onCategorySelected: (value) => selected = value,
        onClearCategory: () async => cleared = true,
      );

      expect(selected, isNull);
      expect(cleared, isTrue);
    });
  });

  group('featuredArxivCategoryCodes', () {
    test('every featured code exists in the category catalog', () {
      for (final code in featuredArxivCategoryCodes) {
        expect(categoryByCode(code), isNotNull, reason: 'Missing category: $code');
      }
    });
  });

  group('categoryForFilterLabel', () {
    test('requires an exact filter label match', () {
      expect(categoryForFilterLabel('cs.LG - Machine Learning')?.code, 'cs.LG');
      expect(categoryForFilterLabel('Machine Learning'), isNull);
      expect(categoryForFilterLabel('cs.LG'), isNull);
    });
  });

  group('category labels', () {
    const category = ArxivCategory(
      code: 'cs.LG',
      label: 'Machine Learning',
      group: 'Computer Science',
    );

    test('categoryChipLabel uses the human-readable label', () {
      expect(categoryChipLabel(category), 'Machine Learning');
    });

    test('categoryFilterLabel combines code and human label', () {
      expect(categoryFilterLabel(category), 'cs.LG - Machine Learning');
    });
  });
}
