// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 3;

  @override
  ChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessage(
      fields[0] as Role,
      fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.role)
      ..writeByte(1)
      ..write(obj.content);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RoleAdapter extends TypeAdapter<Role> {
  @override
  final int typeId = 2;

  @override
  Role read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Role.ai;
      case 1:
        return Role.user;
      case 2:
        return Role.system;
      default:
        return Role.ai;
    }
  }

  @override
  void write(BinaryWriter writer, Role obj) {
    switch (obj) {
      case Role.ai:
        writer.writeByte(0);
        break;
      case Role.user:
        writer.writeByte(1);
        break;
      case Role.system:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
