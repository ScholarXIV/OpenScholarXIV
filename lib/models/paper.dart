import 'package:hive/hive.dart';

part 'paper.g.dart';

@HiveType(typeId: 1)
class Paper {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String summary;
  @HiveField(3)
  final String publishedAt;
  @HiveField(4)
  final String authors;
  @HiveField(5, defaultValue: "")
  final String updatedAt;
  @HiveField(6, defaultValue: "")
  final String abstractUrl;
  @HiveField(7, defaultValue: "")
  final String pdfUrl;
  @HiveField(8, defaultValue: [])
  final List<String> categories;
  @HiveField(9, defaultValue: "")
  final String primaryCategory;
  @HiveField(10, defaultValue: {})
  final Map<String, dynamic> rawEntry;

  Paper(
    this.id,
    this.title,
    this.summary,
    this.publishedAt,
    this.authors, {
    String? updatedAt,
    String? abstractUrl,
    String? pdfUrl,
    List<String>? categories,
    String? primaryCategory,
    Map<String, dynamic>? rawEntry,
  }) : updatedAt = updatedAt ?? "",
       abstractUrl = abstractUrl ?? "",
       pdfUrl = pdfUrl ?? "",
       categories = categories ?? const [],
       primaryCategory = primaryCategory ?? "",
       rawEntry = _castStringKeyMap(rawEntry);

  @override
  String toString() {
    return 'Paper(id: $id, title: $title, summary: $summary, publishedAt: $publishedAt, authors: $authors, updatedAt: $updatedAt, abstractUrl: $abstractUrl, pdfUrl: $pdfUrl, categories: $categories, primaryCategory: $primaryCategory)';
  }

  factory Paper.fromJson(
    Map<String, dynamic> jsonData, {
    Map<String, dynamic>? rawEntry,
  }) {
    final retainedEntry = _castStringKeyMap(rawEntry);
    final fullId = _readText(jsonData["id"]);
    final id = fullId.substring(fullId.lastIndexOf("/") + 1, fullId.length);

    return Paper(
      id,
      _parseLatex(
        _readText(
          jsonData["title"],
        ).replaceAll(RegExp(r'\\n'), '').replaceAll(RegExp(r'\\ '), ''),
      ),
      _parseLatex(
        _readText(
          jsonData["summary"],
        ).trim().replaceAll(RegExp(r'\\n'), ' ').replaceAll(RegExp(r'\\'), ''),
      ),
      _dateOnly(_readText(jsonData["published"])),
      _parseAuthors(jsonData["author"]),
      updatedAt: _readText(jsonData["updated"]),
      abstractUrl: _extractLink(retainedEntry, rel: "alternate") ?? fullId,
      pdfUrl:
          _extractLink(retainedEntry, title: "pdf", type: "application/pdf") ??
          _pdfUrlFromId(id),
      categories: _extractCategories(retainedEntry),
      primaryCategory: _extractPrimaryCategory(retainedEntry),
      rawEntry: retainedEntry,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "summary": summary,
    "published": publishedAt,
    "author": authors,
    "updated": updatedAt,
    "abstractUrl": abstractUrl,
    "pdfUrl": pdfUrl,
    "categories": categories,
    "primaryCategory": primaryCategory,
    "rawEntry": rawEntry,
  };

  Map<String, dynamic> get retainedMetadata => {
    "id": id,
    "title": title,
    "summary": summary,
    "published": publishedAt,
    "updated": updatedAt,
    "authors": authors,
    "abstractUrl": abstractUrl,
    "pdfUrl": pdfUrl,
    "categories": categories,
    "primaryCategory": primaryCategory,
    "rawEntry": rawEntry,
  };

  static bool containsLatex(String title) {
    final latexRegex = RegExp(r'[$\\{}]');
    return latexRegex.hasMatch(title);
  }

  static String _parseLatex(String content) {
    if (containsLatex(content)) {
      return content
          .replaceAll(RegExp(r'\$ '), r' \) ')
          .replaceAll(RegExp(r' \$'), r' \( ')
          .replaceAll(r'$', r' \) ');
    }
    return content;
  }

  static String _dateOnly(String value) {
    if (value.length >= 10) {
      return value.substring(0, 10);
    }
    return value;
  }

  static String _parseAuthors(dynamic authorData) {
    return _asList(authorData)
        .map((author) {
          if (author is Map && author["name"] != null) {
            return _readText(author["name"]);
          }
          return _readText(
            author,
          ).replaceAll("name:", "").replaceAll(RegExp("[\\[\\]\\{\\}]"), "");
        })
        .where((author) => author.trim().isNotEmpty)
        .join(", ");
  }

  static String? _extractLink(
    Map<String, dynamic> rawEntry, {
    String? rel,
    String? title,
    String? type,
  }) {
    for (final link in _asList(rawEntry["link"])) {
      final linkMap = _castStringKeyMap(link);
      if (linkMap.isEmpty) {
        continue;
      }

      final matchesRel = rel == null || linkMap["@rel"] == rel;
      final matchesTitle = title == null || linkMap["@title"] == title;
      final matchesType = type == null || linkMap["@type"] == type;
      if (matchesRel && matchesTitle && matchesType) {
        return linkMap["@href"]?.toString();
      }
    }
    return null;
  }

  static List<String> _extractCategories(Map<String, dynamic> rawEntry) {
    return _asList(rawEntry["category"])
        .map((category) => _castStringKeyMap(category)["@term"]?.toString())
        .whereType<String>()
        .where((category) => category.isNotEmpty)
        .toList();
  }

  static String _extractPrimaryCategory(Map<String, dynamic> rawEntry) {
    final primaryCategory = _castStringKeyMap(
      rawEntry["arxiv:primary_category"],
    );
    return primaryCategory["@term"]?.toString() ?? "";
  }

  static String _pdfUrlFromId(String id) {
    if (id.contains(".") == true) {
      return "https://arxiv.org/pdf/$id";
    }
    return "https://arxiv.org/pdf/cond-mat/$id";
  }
}

Map<String, dynamic> _castStringKeyMap(dynamic value) {
  if (value is! Map) {
    return {};
  }

  return value.map(
    (key, value) => MapEntry(key.toString(), _castRetainedValue(value)),
  );
}

dynamic _castRetainedValue(dynamic value) {
  if (value is Map) {
    return _castStringKeyMap(value);
  }
  if (value is List) {
    return value.map(_castRetainedValue).toList();
  }
  return value;
}

List<dynamic> _asList(dynamic value) {
  if (value == null) {
    return [];
  }
  if (value is List) {
    return value;
  }
  return [value];
}

String _readText(dynamic value) {
  if (value == null) {
    return "";
  }
  if (value is Map && value[r"$"] != null) {
    return value[r"$"].toString();
  }
  return value.toString();
}
