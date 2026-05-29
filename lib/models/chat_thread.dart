import 'package:arxiv/models/chat_message.dart';
import 'package:arxiv/models/paper.dart';
import 'package:hive/hive.dart';

part 'chat_thread.g.dart';

@HiveType(typeId: 4)
class ChatThread {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  String modelName;

  @HiveField(5)
  Paper? paperData;

  @HiveField(6)
  List<ChatMessage> messages;

  ChatThread({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.modelName,
    this.paperData,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];
}
