import 'package:arxiv/models/paper.dart';
import 'package:arxiv/services/citation_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CitationFormatter builds BibTeX, APA, and abstract links', () {
    final paper = Paper(
      '1234.56789v2',
      'A useful research paper',
      'A sample abstract.',
      '2026-01-02',
      'Ada Lovelace, Alan Turing',
      abstractUrl: 'https://arxiv.org/abs/1234.56789v2',
      primaryCategory: 'cs.AI',
    );

    expect(CitationFormatter.bibtexKey(paper), 'arxiv_1234_56789');
    expect(CitationFormatter.abstractUrl(paper), paper.abstractUrl);
    expect(
      CitationFormatter.apa(paper),
      'Ada Lovelace, Alan Turing. (2026). A useful research paper. arXiv:1234.56789. https://arxiv.org/abs/1234.56789v2',
    );
    expect(
      CitationFormatter.bibtex(paper),
      contains('author={Ada Lovelace and Alan Turing}'),
    );
    expect(CitationFormatter.bibtex(paper), contains('year={2026}'));
    expect(CitationFormatter.bibtex(paper), contains('primaryClass={cs.AI}'));
  });

  test('CitationFormatter falls back to arXiv abstract URL from paper ID', () {
    final paper = Paper(
      'hep-th/9901001v1',
      'A legacy arXiv paper',
      'A sample abstract.',
      '',
      'Grace Hopper',
    );

    expect(
      CitationFormatter.abstractUrl(paper),
      'https://arxiv.org/abs/hep-th/9901001v1',
    );
  });
}
