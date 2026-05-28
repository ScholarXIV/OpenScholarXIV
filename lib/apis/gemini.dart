import 'package:arxiv/models/chat_message.dart';
import 'package:arxiv/models/paper.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/services.dart' show rootBundle;

class Gemini {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  Gemini._internal(String apiKey, String systemPrompt) {
    _model = GenerativeModel(
      apiKey: apiKey,
      model: 'gemini-2.5-flash',
      systemInstruction: Content.system(systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 1,
        topK: 64,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: 'text/plain',
      ),
    );

    _chatSession = _model.startChat();
  }

  static Future<Gemini> newModel(String apiKey, {Paper? paper}) async {
    final systemPrompt = paper != null
        ? await _getModelSystemMessage(paper)
        : await _getGeneralSystemMessage();
    return Gemini._internal(apiKey, systemPrompt);
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
        'assets/system_message_templates/model.txt', substitutes);
  }

  static Future<String> _getGeneralSystemMessage() async {
    return await _fromTemplateFile(
        'assets/system_message_templates/general.txt', {});
  }

  /// Interpolates values to a text read from a file. The format for a placeholder is {{some_name}}.
  static Future<String> _fromTemplateFile(
      String fileName, Map<String, dynamic> substitutes) async {
    var template = await rootBundle.loadString(fileName);
    return template.splitMapJoin(RegExp('{{.*?}}'),
        onMatch: (m) => substitutes[_getPlaceholderName(m.group(0))] ?? '');
  }

  static String _getPlaceholderName(String? placeholderTemplate) {
    if (placeholderTemplate == null) return '';

    return placeholderTemplate.substring(2, placeholderTemplate.length - 2);
  }
}
