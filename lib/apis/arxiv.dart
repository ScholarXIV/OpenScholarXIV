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
    this.errorMessage,
    this.statusCode,
  });

  final List<Paper> papers;
  final Map<String, dynamic> feed;
  final Map<String, dynamic> rawResponse;
  final String rawXml;
  final String? errorMessage;
  final int? statusCode;

  bool get hasError => errorMessage?.isNotEmpty == true;

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
  static const _host = "export.arxiv.org";
  static const _path = "/api/query";
  static const _minimumRequestInterval = Duration(seconds: 3);

  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 8),
      responseType: ResponseType.plain,
    ),
  );
  static Future<void> _requestQueue = Future.value();
  static DateTime? _lastRequestStartedAt;

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
    return _runRateLimitedRequest(
      () => _searchWithMetadata(term, page: page, pageSize: pageSize),
    );
  }

  static Future<ArxivSearchResult> _searchWithMetadata(
    String term, {
    int page = 0,
    int pageSize = 30,
  }) async {
    final parkerXml = Xml2Json();
    final rawXml = Xml2Json();

    try {
      final response = await _dio.getUri<String>(
        queryUriFor(term, page: page, pageSize: pageSize),
      );
      final responseXml = response.data?.toString() ?? "";
      if (responseXml.trim().isEmpty) {
        return _failure(
          "arXiv returned an empty response. Please try again.",
          statusCode: response.statusCode,
        );
      }

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
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return _failure(
        _messageForDioException(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return _failure("Could not read the arXiv response. Please try again.");
    }
  }

  static Uri queryUriFor(String term, {int page = 0, int pageSize = 30}) {
    return Uri.https(_host, _path, {
      "search_query": searchQueryFor(term),
      "start": page.toString(),
      "max_results": pageSize.toString(),
    });
  }

  static String searchQueryFor(String term) {
    final trimmedTerm = term.trim();
    if (_isArxivFieldQuery(trimmedTerm)) {
      return trimmedTerm;
    }
    return "all:$trimmedTerm";
  }

  static bool _isArxivFieldQuery(String term) {
    return RegExp(
      r'^(all|ti|au|abs|co|jr|cat|rn|id):',
      caseSensitive: false,
    ).hasMatch(term);
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

  static Future<T> _runRateLimitedRequest<T>(Future<T> Function() request) {
    final queuedRequest = _requestQueue.then((_) async {
      final lastRequestStartedAt = _lastRequestStartedAt;
      if (lastRequestStartedAt != null) {
        final nextAllowedStart = lastRequestStartedAt.add(
          _minimumRequestInterval,
        );
        final wait = nextAllowedStart.difference(DateTime.now());
        if (!wait.isNegative) {
          await Future.delayed(wait);
        }
      }

      _lastRequestStartedAt = DateTime.now();
      return request();
    });

    _requestQueue = queuedRequest.then((_) {}, onError: (_) {});
    return queuedRequest;
  }

  static ArxivSearchResult _failure(String message, {int? statusCode}) {
    return ArxivSearchResult(
      papers: const [],
      feed: const {},
      rawResponse: const {},
      rawXml: "",
      errorMessage: message,
      statusCode: statusCode,
    );
  }

  static String _messageForDioException(DioException exception) {
    final statusCode = exception.response?.statusCode;
    if (statusCode == 429) {
      return "arXiv is rate limiting requests. Please wait a few seconds and try again.";
    }
    if (statusCode != null) {
      return "arXiv returned HTTP $statusCode. Please try again.";
    }

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return "arXiv took too long to respond. Please try again.";
      case DioExceptionType.connectionError:
        return "Could not reach arXiv. Check your connection and try again.";
      case DioExceptionType.cancel:
        return "The arXiv request was cancelled. Please try again.";
      case DioExceptionType.badCertificate:
        return "Could not verify arXiv's secure connection.";
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return "Could not fetch papers from arXiv. Please try again.";
    }
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
