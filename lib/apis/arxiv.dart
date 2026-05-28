import 'dart:convert';
import 'dart:math';

import 'package:arxiv/models/paper.dart';
import 'package:dio/dio.dart';
import 'package:xml2json/xml2json.dart';

class ArxivSearchResult {
  const ArxivSearchResult({
    required this.papers,
    required this.feed,
    required this.rawResponse,
    required this.rawXml,
  });

  final List<Paper> papers;
  final Map<String, dynamic> feed;
  final Map<String, dynamic> rawResponse;
  final String rawXml;

  int get totalResults => _readInt(feed["opensearch:totalResults"]);
  int get startIndex => _readInt(feed["opensearch:startIndex"]);
  int get itemsPerPage => _readInt(feed["opensearch:itemsPerPage"]);

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }
}

class Arxiv {
  static const _baseUrl = "http://export.arxiv.org/api/query?search_query=all";

  static final _dio = Dio();

  static const _topics = [
    "acid",
    "a theory of justice",
    "attention is all you need",
    "augmented",
    "behavioral",
    "books",
    "black hole",
    "brain",
    "cats",
    "computer",
    "creative",
    "dog",
    "dna sequencing",
    "dyson sphere",
    "ecg",
    "emotional",
    "entanglement",
    "fear",
    "fuzzy sets",
    "fidgeting",
    "glucose",
    "garbage",
    "gonad",
    "hands",
    "heart",
    "higgs boson",
    "hydron",
    "identity",
    "industrial",
    "isolation",
    "laptop",
    "love",
    "laboratory",
    "machine learning",
    "mathematical theory of communication",
    "mental state",
    "micro",
    "microchip",
    "mobile",
    "molecular cloning",
    "neural network",
    "negative",
    "numbers",
    "pc",
    "planet",
    "protein measurement",
    "psychology",
    "quantum",
    "quasar",
    "qubit",
    "reading",
    "relationship",
    "relativity",
    "robotics",
    "rocket",
    "sitting",
    "spider",
    "spiritual",
    "sulphur",
    "television",
    "tiered reward",
    "transport",
    "virtual reality",
    "volcano",
    "vision",
  ];

  /// Fetches papers for the requested [term].
  /// [page] and [pageSize] are optional. If missing, 0 and 30 are used as defaults respectively.
  static Future<ArxivSearchResult> searchWithMetadata(
    String term, {
    int page = 0,
    int pageSize = 30,
  }) async {
    final parkerXml = Xml2Json();
    final rawXml = Xml2Json();

    try {
      var response = await _dio.get(
        "$_baseUrl:$term&start=$page&max_results=$pageSize",
      );
      final responseXml = response.data.toString();

      parkerXml.parse(responseXml);
      rawXml.parse(responseXml);

      final jsonData = _asMap(json.decode(parkerXml.toParker()));
      final rawData = _asMap(json.decode(rawXml.toBadgerfish()));
      final feed = _asMap(jsonData["feed"]);
      final rawFeed = _asMap(rawData["feed"]);
      final entries = _asList(feed["entry"]);
      final rawEntries = _asList(rawFeed["entry"]);

      final papers = <Paper>[];
      for (var index = 0; index < entries.length; index++) {
        papers.add(
          Paper.fromJson(
            _asMap(entries[index]),
            rawEntry: index < rawEntries.length
                ? _asMap(rawEntries[index])
                : const {},
          ),
        );
      }

      return ArxivSearchResult(
        papers: papers,
        feed: feed,
        rawResponse: rawData,
        rawXml: responseXml,
      );
    } catch (e) {
      return const ArxivSearchResult(
        papers: [],
        feed: {},
        rawResponse: {},
        rawXml: "",
      );
    }
  }

  static Future<List<Paper>> search(
    String term, {
    int page = 0,
    int pageSize = 30,
  }) async {
    final result = await searchWithMetadata(
      term,
      page: page,
      pageSize: pageSize,
    );
    return result.papers;
  }

  /// Fetches papers for a random topic.
  static Future<ArxivSearchResult> suggestWithMetadata({int pageSize = 30}) {
    Random random = Random();
    int randomIndex = random.nextInt(_topics.length);
    String topic = _topics[randomIndex];

    return searchWithMetadata(topic, pageSize: pageSize);
  }

  static Future<List<Paper>> suggest({int pageSize = 30}) {
    return suggestWithMetadata(
      pageSize: pageSize,
    ).then((result) => result.papers);
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return {};
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
