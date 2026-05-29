// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paper_note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaperNoteAdapter extends TypeAdapter<PaperNote> {
  @override
  final int typeId = 5;

  @override
  PaperNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaperNote(
      id: fields[0] as String,
      paperId: fields[1] as String,
      paperTitle: fields[2] as String,
      body: fields[3] as String,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      paper: fields[6] as Paper?,
    );
  }

  @override
  void write(BinaryWriter writer, PaperNote obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.paperId)
      ..writeByte(2)
      ..write(obj.paperTitle)
      ..writeByte(3)
      ..write(obj.body)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.paper);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaperNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
