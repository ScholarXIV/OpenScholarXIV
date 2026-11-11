import 'package:hive/hive.dart';

/// Reads and writes the user's AI provider settings (API key and chosen model).
///
/// Keeping this in one place means the rest of the app never touches the
/// underlying box directly, so the storage backend can change later without
/// editing the UI.
class ApiSettingsStore {
  static const boxName = "apibox";
  static const apiKeyField = "apikey";
  static const geminiModelField = "geminiModel";

  // The box is left open on purpose: closing it here could pull it out from
  // under another read or write that is still in flight.
  Future<Box> _box() => Hive.openBox(boxName);

  Future<String> loadApiKey() async {
    final stored = (await _box()).get(apiKeyField);
    return stored is String ? stored.trim() : "";
  }

  Future<void> saveApiKey(String apiKey) async {
    await (await _box()).put(apiKeyField, apiKey.trim());
  }

  Future<void> clearApiKey() async {
    await (await _box()).delete(apiKeyField);
  }

  Future<String?> loadGeminiModel() async {
    final stored = (await _box()).get(geminiModelField);
    return stored is String && stored.isNotEmpty ? stored : null;
  }

  Future<void> saveGeminiModel(String modelName) async {
    await (await _box()).put(geminiModelField, modelName);
  }

  /// Hides all but the last four characters, so a saved key can be recognised
  /// on screen without being readable over a shoulder or in a screenshot.
  static String maskApiKey(String apiKey) {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) return "";

    const visibleCharacters = 4;
    const mask = "••••••••";
    if (trimmed.length <= visibleCharacters * 2) return mask;

    return mask + trimmed.substring(trimmed.length - visibleCharacters);
  }
}
