import 'package:arxiv/models/chat_message.dart';
import 'package:arxiv/models/chat_thread.dart';
import 'package:arxiv/models/paper.dart';
import 'package:hive/hive.dart';

class ChatHistoryStore {
  static const boxName = "chatThreads";

  Future<List<ChatThread>> loadThreads() async {
    final box = await Hive.openBox<ChatThread>(boxName);
    final threads = box.values.toList()
      ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    await box.close();
    return threads;
  }

  Future<ChatThread> createThread({
    required String modelName,
    required List<ChatMessage> messages,
    Paper? paperData,
    String? title,
  }) async {
    final box = await Hive.openBox<ChatThread>(boxName);
    final now = DateTime.now();
    final thread = ChatThread(
      id: "chat_${now.microsecondsSinceEpoch}",
      title: normalizeTitle(title) ?? titleFromMessages(messages, paperData),
      createdAt: now,
      updatedAt: now,
      modelName: modelName,
      paperData: paperData,
      messages: List<ChatMessage>.from(messages),
    );

    await box.put(thread.id, thread);
    await box.close();
    return thread;
  }

  Future<void> saveThread(ChatThread thread) async {
    final box = await Hive.openBox<ChatThread>(boxName);
    thread.updatedAt = DateTime.now();
    await box.put(thread.id, thread);
    await box.close();
  }

  Future<void> renameThread(ChatThread thread, String title) async {
    final normalizedTitle = normalizeTitle(title);
    if (normalizedTitle == null) return;

    thread.title = normalizedTitle;
    await saveThread(thread);
  }

  Future<void> deleteThread(String id) async {
    final box = await Hive.openBox<ChatThread>(boxName);
    await box.delete(id);
    await box.close();
  }

  static String titleFromMessages(
    List<ChatMessage> messages,
    Paper? paperData,
  ) {
    for (final message in messages) {
      if (message.role == Role.user) {
        final normalizedContent = _normalizeWhitespace(message.content);
        if (normalizedContent.isNotEmpty) {
          return _truncateTitle(normalizedContent);
        }
      }
    }

    final paperTitle = normalizeTitle(paperData?.title);
    return paperTitle ?? "New chat";
  }

  static String? normalizeTitle(String? title) {
    final normalizedTitle = _normalizeWhitespace(title ?? "");
    if (normalizedTitle.isEmpty) return null;
    return _truncateTitle(normalizedTitle);
  }

  static String _normalizeWhitespace(String value) {
    return value.trim().replaceAll(RegExp(r"\s+"), " ");
  }

  static String _truncateTitle(String value) {
    const maxLength = 48;
    if (value.length <= maxLength) return value;
    return "${value.substring(0, maxLength - 3).trimRight()}...";
  }
}
