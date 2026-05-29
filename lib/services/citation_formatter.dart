import 'package:arxiv/models/paper.dart';

class CitationFormatter {
  static String bibtex(Paper paper) {
    final arxivId = _baseArxivId(paper.id);
    final year = _yearFromDate(paper.publishedAt);
    final fields = <String>[
      'title={${_escapeBibtex(paper.title)}}',
      'author={${_authorsForBibtex(paper.authors)}}',
      if (year.isNotEmpty) 'year={$year}',
      'eprint={$arxivId}',
      'archivePrefix={arXiv}',
      if (paper.primaryCategory.isNotEmpty)
        'primaryClass={${paper.primaryCategory}}',
      'url={${abstractUrl(paper)}}',
    ];

    return "@article{${bibtexKey(paper)},\n"
        "${fields.map((field) => "  $field").join(",\n")}\n"
        "}";
  }

  static String apa(Paper paper) {
    final year = _yearFromDate(paper.publishedAt);
    final yearText = year.isEmpty ? "n.d." : year;
    final arxivId = _baseArxivId(paper.id);

    return "${paper.authors}. ($yearText). ${paper.title}. arXiv:$arxivId. ${abstractUrl(paper)}";
  }

  static String abstractUrl(Paper paper) {
    if (paper.abstractUrl.trim().isNotEmpty) {
      return paper.abstractUrl.trim();
    }

    final id = paper.id.trim();
    if (id.startsWith("http")) {
      return id.replaceFirst("/pdf/", "/abs/");
    }

    return "https://arxiv.org/abs/$id";
  }

  static String bibtexKey(Paper paper) {
    return "arxiv_${_baseArxivId(paper.id).replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}";
  }

  static String _authorsForBibtex(String authors) {
    return authors
        .split(",")
        .map((author) => author.trim())
        .where((author) => author.isNotEmpty)
        .join(" and ");
  }

  static String _baseArxivId(String id) {
    final trimmedId = id.trim();
    final lastSegment = trimmedId.substring(trimmedId.lastIndexOf("/") + 1);
    return lastSegment.replaceFirst(RegExp(r'v\d+$'), '');
  }

  static String _yearFromDate(String date) {
    final trimmedDate = date.trim();
    if (trimmedDate.length >= 4) {
      return trimmedDate.substring(0, 4);
    }
    return "";
  }

  static String _escapeBibtex(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('{', r'\{')
        .replaceAll('}', r'\}');
  }
}
