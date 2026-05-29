import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 2)
enum Role {
  @HiveField(0)
  ai,
  @HiveField(1)
  user,
  @HiveField(2)
  system,
}

@HiveType(typeId: 3)
class ChatMessage {
  @HiveField(0)
  Role role;
  @HiveField(1)
  String content;

  ChatMessage(this.role, this.content);
}
