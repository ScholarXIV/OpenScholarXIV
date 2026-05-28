// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paper.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaperAdapter extends TypeAdapter<Paper> {
  @override
  final int typeId = 1;

  @override
  Paper read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Paper(
      fields[0] as String,
      fields[1] as String,
      fields[2] as String,
      fields[3] as String,
      fields[4] as String,
      updatedAt: fields[5] == null ? '' : fields[5] as String?,
      abstractUrl: fields[6] == null ? '' : fields[6] as String?,
      pdfUrl: fields[7] == null ? '' : fields[7] as String?,
      categories: fields[8] == null ? [] : (fields[8] as List?)?.cast<String>(),
      primaryCategory: fields[9] == null ? '' : fields[9] as String?,
      rawEntry: fields[10] == null
          ? {}
          : (fields[10] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, Paper obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.summary)
      ..writeByte(3)
      ..write(obj.publishedAt)
      ..writeByte(4)
      ..write(obj.authors)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.abstractUrl)
      ..writeByte(7)
      ..write(obj.pdfUrl)
      ..writeByte(8)
      ..write(obj.categories)
      ..writeByte(9)
      ..write(obj.primaryCategory)
      ..writeByte(10)
      ..write(obj.rawEntry);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaperAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
