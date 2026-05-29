// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_thread.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatThreadAdapter extends TypeAdapter<ChatThread> {
  @override
  final int typeId = 4;

  @override
  ChatThread read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatThread(
      id: fields[0] as String,
      title: fields[1] as String,
      createdAt: fields[2] as DateTime,
      updatedAt: fields[3] as DateTime,
      modelName: fields[4] as String,
      paperData: fields[5] as Paper?,
      messages: (fields[6] as List?)?.cast<ChatMessage>(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatThread obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.modelName)
      ..writeByte(5)
      ..write(obj.paperData)
      ..writeByte(6)
      ..write(obj.messages);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatThreadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
