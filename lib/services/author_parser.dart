import 'package:arxiv/models/paper.dart';

class AuthorParser {
  static const _suffixes = {
    "jr",
    "jr.",
    "sr",
    "sr.",
    "ii",
    "iii",
    "iv",
    "v",
    "vi",
    "phd",
    "ph.d.",
    "md",
    "m.d.",
    "dphil",
    "esq",
    "esq.",
  };

  static List<String> authorsForPaper(Paper paper) {
    final rawAuthors = _authorsFromRawEntry(paper.rawEntry);
    if (rawAuthors.isNotEmpty) return rawAuthors;

    return _authorsFromDisplayString(paper.authors);
  }

  static String authorQueryFor(String author) {
    final normalizedAuthor = _normalizeWhitespace(author);
    final escapedAuthor = normalizedAuthor
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"');
    return 'au:"$escapedAuthor"';
  }

  static List<String> _authorsFromRawEntry(Map<String, dynamic> rawEntry) {
    return _asList(rawEntry["author"])
        .map(_authorNameFromRawValue)
        .where((author) => author.isNotEmpty)
        .toList();
  }

  static String _authorNameFromRawValue(dynamic value) {
    if (value is Map) {
      final name = value["name"];
      if (name is Map && name[r"$"] != null) {
        return _normalizeWhitespace(name[r"$"].toString());
      }
      if (name != null) {
        return _normalizeWhitespace(name.toString());
      }
    }

    return _normalizeWhitespace(value?.toString() ?? "");
  }

  static List<String> _authorsFromDisplayString(String authors) {
    final parts = authors
        .split(",")
        .map(_normalizeWhitespace)
        .where((part) => part.isNotEmpty)
        .toList();
    final parsedAuthors = <String>[];

    for (final part in parts) {
      if (parsedAuthors.isNotEmpty && _isSuffix(part)) {
        parsedAuthors[parsedAuthors.length - 1] =
            "${parsedAuthors.last}, $part";
      } else {
        parsedAuthors.add(part);
      }
    }

    return parsedAuthors;
  }

  static bool _isSuffix(String value) {
    return _suffixes.contains(
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ''),
    );
  }

  static List<dynamic> _asList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value;
    return [value];
  }

  static String _normalizeWhitespace(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), " ");
  }
}
