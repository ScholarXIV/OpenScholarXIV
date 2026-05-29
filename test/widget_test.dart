import 'package:arxiv/apis/arxiv.dart';
import 'package:arxiv/models/paper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Arxiv.queryUriFor builds an encoded HTTPS query', () {
    final uri = Arxiv.queryUriFor('machine learning', page: 30, pageSize: 10);

    expect(uri.scheme, 'https');
    expect(uri.host, 'export.arxiv.org');
    expect(uri.path, '/api/query');
    expect(uri.queryParameters['search_query'], 'all:machine learning');
    expect(uri.queryParameters['start'], '30');
    expect(uri.queryParameters['max_results'], '10');
  });

  test('Arxiv.queryUriFor passes arXiv field queries through', () {
    final categoryUri = Arxiv.queryUriFor('cat:cs.AI');
    final authorUri = Arxiv.queryUriFor('au:"Ada Lovelace"');

    expect(categoryUri.queryParameters['search_query'], 'cat:cs.AI');
    expect(authorUri.queryParameters['search_query'], 'au:"Ada Lovelace"');
  });

  test('Paper.fromJson retains arXiv entry metadata', () {
    final paper = Paper.fromJson(
      {
        "id": "http://arxiv.org/abs/1234.56789v1",
        "title": "A retained metadata example",
        "summary": "A sample abstract.",
        "published": "2026-01-02T03:04:05Z",
        "updated": "2026-01-03T03:04:05Z",
        "author": {"name": "Ada Lovelace"},
      },
      rawEntry: {
        "id": {r"$": "http://arxiv.org/abs/1234.56789v1"},
        "title": {r"$": "A retained metadata example"},
        "updated": {r"$": "2026-01-03T03:04:05Z"},
        "link": [
          {
            "@href": "https://arxiv.org/abs/1234.56789v1",
            "@rel": "alternate",
            "@type": "text/html",
          },
          {
            "@href": "https://arxiv.org/pdf/1234.56789v1",
            "@rel": "related",
            "@type": "application/pdf",
            "@title": "pdf",
          },
        ],
        "summary": {r"$": "A sample abstract."},
        "category": {
          "@term": "cs.AI",
          "@scheme": "http://arxiv.org/schemas/atom",
        },
        "published": {r"$": "2026-01-02T03:04:05Z"},
        "arxiv:primary_category": {
          "@term": "cs.AI",
          "@scheme": "http://arxiv.org/schemas/atom",
        },
        "author": {
          "name": {r"$": "Ada Lovelace"},
        },
      },
    );

    expect(paper.id, "1234.56789v1");
    expect(paper.publishedAt, "2026-01-02");
    expect(paper.updatedAt, "2026-01-03T03:04:05Z");
    expect(paper.abstractUrl, "https://arxiv.org/abs/1234.56789v1");
    expect(paper.pdfUrl, "https://arxiv.org/pdf/1234.56789v1");
    expect(paper.categories, ["cs.AI"]);
    expect(paper.primaryCategory, "cs.AI");
    expect(paper.rawEntry["link"], isA<List>());
    expect(paper.retainedMetadata["rawEntry"], paper.rawEntry);
  });
}
