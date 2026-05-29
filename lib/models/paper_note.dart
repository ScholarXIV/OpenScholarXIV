import 'package:arxiv/models/paper.dart';
import 'package:hive/hive.dart';

part 'paper_note.g.dart';

@HiveType(typeId: 5)
class PaperNote {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String paperId;

  @HiveField(2)
  final String paperTitle;

  @HiveField(3)
  String body;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  Paper? paper;

  PaperNote({
    required this.id,
    required this.paperId,
    required this.paperTitle,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.paper,
  });
}
