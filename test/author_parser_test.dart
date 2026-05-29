import 'package:arxiv/models/paper.dart';
import 'package:arxiv/services/author_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AuthorParser prefers retained raw arXiv author entries', () {
    final paper = Paper(
      '1234.56789v1',
      'A paper',
      'A sample abstract.',
      '2026-01-02',
      'Fallback Author',
      rawEntry: {
        'author': [
          {
            'name': {r'$': 'Ada Lovelace Jr.'},
          },
          {
            'name': {r'$': 'Alan M. Turing III'},
          },
        ],
      },
    );

    expect(AuthorParser.authorsForPaper(paper), [
      'Ada Lovelace Jr.',
      'Alan M. Turing III',
    ]);
  });

  test('AuthorParser keeps suffix-only comma parts with previous author', () {
    final paper = Paper(
      '1234.56789v1',
      'A paper',
      'A sample abstract.',
      '2026-01-02',
      'Ada Lovelace, Jr., Alan Turing, Grace Hopper, PhD',
    );

    expect(AuthorParser.authorsForPaper(paper), [
      'Ada Lovelace, Jr.',
      'Alan Turing',
      'Grace Hopper, PhD',
    ]);
  });

  test('AuthorParser builds quoted arXiv author queries', () {
    expect(
      AuthorParser.authorQueryFor('Alan "Al" Turing'),
      r'au:"Alan \"Al\" Turing"',
    );
  });
}
