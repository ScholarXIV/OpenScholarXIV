import 'dart:io';

import 'package:arxiv/services/api_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDirectory;
  final store = ApiSettingsStore();

  setUpAll(() {
    tempDirectory = Directory.systemTemp.createTempSync(
      'api_settings_store_test_',
    );
    Hive.init(tempDirectory.path);
  });

  tearDown(() async {
    if (Hive.isBoxOpen(ApiSettingsStore.boxName)) {
      await Hive.box(ApiSettingsStore.boxName).close();
    }
    try {
      await Hive.deleteBoxFromDisk(ApiSettingsStore.boxName);
    } catch (_) {
      // The box may not exist if a test fails before opening it.
    }
  });

  tearDownAll(() async {
    await Hive.close();
    tempDirectory.deleteSync(recursive: true);
  });

  test('returns an empty key and no model before anything is saved', () async {
    expect(await store.loadApiKey(), "");
    expect(await store.loadGeminiModel(), isNull);
  });

  test('saves, trims, and clears the API key', () async {
    await store.saveApiKey("  my-secret-key \n");
    expect(await store.loadApiKey(), "my-secret-key");

    await store.clearApiKey();
    expect(await store.loadApiKey(), "");
  });

  test('clearing the key keeps the selected model', () async {
    await store.saveApiKey("my-secret-key");
    await store.saveGeminiModel("gemini-2.5-pro");

    await store.clearApiKey();

    expect(await store.loadGeminiModel(), "gemini-2.5-pro");
  });

  test('reads keys written by earlier app versions', () async {
    final box = await Hive.openBox(ApiSettingsStore.boxName);
    await box.put("apikey", "legacy-key");
    await box.put("geminiModel", "gemini-2.5-flash");
    await Hive.close();

    expect(await store.loadApiKey(), "legacy-key");
    expect(await store.loadGeminiModel(), "gemini-2.5-flash");
  });

  test(
    'treats the empty string older versions stored on clear as no key',
    () async {
      final box = await Hive.openBox(ApiSettingsStore.boxName);
      await box.put("apikey", "");

      expect(await store.loadApiKey(), "");
    },
  );

  group('maskApiKey', () {
    test('shows only the last four characters', () {
      final masked = ApiSettingsStore.maskApiKey("AIzaSyExampleKey1234");

      expect(masked, endsWith("1234"));
      expect(masked, isNot(contains("AIzaSy")));
      expect(masked, isNot(contains("ExampleKey")));
    });

    test('reveals nothing for short keys', () {
      expect(ApiSettingsStore.maskApiKey("12345678"), isNot(contains("5678")));
    });

    test('returns an empty string when there is no key', () {
      expect(ApiSettingsStore.maskApiKey("   "), "");
    });
  });
}
