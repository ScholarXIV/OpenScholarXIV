import 'package:arxiv/models/chat_message.dart';
import 'package:arxiv/models/paper.dart';
import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/services.dart' show rootBundle;

class GeminiModelOption {
  const GeminiModelOption({required this.id, required this.label});

  final String id;
  final String label;

  factory GeminiModelOption.fallback() {
    return GeminiModelOption(
      id: Gemini.defaultModelName,
      label: labelFromModelName(Gemini.defaultModelName),
    );
  }

  factory GeminiModelOption.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '';
    final baseModelId = json['baseModelId']?.toString() ?? '';
    final modelId = baseModelId.isNotEmpty
        ? baseModelId
        : name.startsWith('models/')
        ? name.substring('models/'.length)
        : baseModelId;

    return GeminiModelOption(
      id: modelId,
      label: json['displayName']?.toString() ?? labelFromModelName(modelId),
    );
  }

  static String labelFromModelName(String modelName) {
    final id = modelName.replaceFirst('models/', '');
    return id
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}

class Gemini {
  static const defaultModelName = 'gemini-2.5-flash';
  static final _dio = Dio();

  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  Gemini._internal(
    String apiKey,
    String systemPrompt,
    String modelName, {
    List<ChatMessage> history = const [],
  }) {
    _model = GenerativeModel(
      apiKey: apiKey,
      model: modelName,
      systemInstruction: Content.system(systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 1,
        topK: 64,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: 'text/plain',
      ),
    );

    _chatSession = _model.startChat(history: _contentHistoryFor(history));
  }

  static Future<Gemini> newModel(
    String apiKey, {
    Paper? paper,
    String modelName = defaultModelName,
    List<ChatMessage> history = const [],
  }) async {
    final systemPrompt = paper != null
        ? await _getModelSystemMessage(paper)
        : await _getGeneralSystemMessage();
    return Gemini._internal(apiKey, systemPrompt, modelName, history: history);
  }

  static List<Content> _contentHistoryFor(List<ChatMessage> messages) {
    final history = <Content>[];

    for (final message in messages) {
      final content = message.content.trim();
      if (content.isEmpty || message.role == Role.system) {
        continue;
      }

      if (message.role == Role.user) {
        history.add(Content.text(content));
      } else {
        history.add(Content.model([TextPart(content)]));
      }
    }

    return history;
  }

  static bool _isTextChatModel(Map<String, dynamic> rawModel) {
    final methods = rawModel['supportedGenerationMethods'];
    final supportsGenerateContent =
        methods is List && methods.contains('generateContent');

    if (!supportsGenerateContent) return false;

    final searchableFields = [
      rawModel['name'],
      rawModel['baseModelId'],
      rawModel['displayName'],
      rawModel['description'],
    ].whereType<String>().join(' ').toLowerCase();

    if (!searchableFields.contains('gemini-')) return false;

    const excludedTerms = [
      'antigravity',
      'agent',
      'audio',
      'computer use',
      'computer-use',
      'deep research',
      'embedding',
      'image',
      'imagen',
      'live',
      'lyria',
      'nano banana',
      'robotics',
      'tts',
      'veo',
      'vision',
    ];

    return !excludedTerms.any(searchableFields.contains);
  }

  static Future<List<GeminiModelOption>> listModels(String apiKey) async {
    try {
      final response = await _dio.get(
        'https://generativelanguage.googleapis.com/v1beta/models',
        queryParameters: {'key': apiKey},
      );
      final data = response.data;

      if (data is! Map<String, dynamic>) return [GeminiModelOption.fallback()];

      final rawModels = data['models'];
      if (rawModels is! List) return [GeminiModelOption.fallback()];

      final modelOptions =
          rawModels
              .whereType<Map>()
              .map((rawModel) => rawModel.cast<String, dynamic>())
              .where(_isTextChatModel)
              .map((rawModel) {
                return GeminiModelOption.fromJson(rawModel);
              })
              .where((modelOption) => modelOption.id.isNotEmpty)
              .toList()
            ..sort((first, second) => first.label.compareTo(second.label));

      return modelOptions.isEmpty
          ? [GeminiModelOption.fallback()]
          : modelOptions;
    } catch (e) {
      return [GeminiModelOption.fallback()];
    }
  }

  Future<ChatMessage> sendMessage(String message) async {
    try {
      var content = Content.text(message);
      var response = await _chatSession.sendMessage(content);
      return ChatMessage(Role.ai, response.text?.trim() ?? "");
    } catch (e) {
      return ChatMessage(Role.ai, e.toString());
    }
  }

  static Future<String> _getModelSystemMessage(Paper paper) async {
    var substitutes = {
      'paperId': paper.id,
      'paperTitle': paper.title,
      'paperAuthors': paper.authors,
      'paperPublishedDate': paper.publishedAt,
      'paperSummary': paper.summary,
    };

    return await _fromTemplateFile(
      'assets/system_message_templates/model.txt',
      substitutes,
    );
  }

  static Future<String> _getGeneralSystemMessage() async {
    return await _fromTemplateFile(
      'assets/system_message_templates/general.txt',
      {},
    );
  }

  /// Interpolates values to a text read from a file. The format for a placeholder is {{some_name}}.
  static Future<String> _fromTemplateFile(
    String fileName,
    Map<String, dynamic> substitutes,
  ) async {
    var template = await rootBundle.loadString(fileName);
    return template.splitMapJoin(
      RegExp('{{.*?}}'),
      onMatch: (m) => substitutes[_getPlaceholderName(m.group(0))] ?? '',
    );
  }

  static String _getPlaceholderName(String? placeholderTemplate) {
    if (placeholderTemplate == null) return '';

    return placeholderTemplate.substring(2, placeholderTemplate.length - 2);
  }
}
