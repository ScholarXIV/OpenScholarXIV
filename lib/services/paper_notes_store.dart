import 'package:arxiv/models/paper.dart';
import 'package:arxiv/models/paper_note.dart';
import 'package:hive/hive.dart';

class PaperNotesStore {
  static const boxName = "paperNotes";
  static Future<Box<PaperNote>>? _boxFuture;

  Future<Box<PaperNote>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<PaperNote>(boxName);
    }

    _boxFuture ??= Hive.openBox<PaperNote>(boxName);
    final box = await _boxFuture!;
    if (!box.isOpen) {
      _boxFuture = null;
      return _openBox();
    }
    return box;
  }

  Future<List<PaperNote>> loadNotes() async {
    final box = await _openBox();
    final notes = box.values.toList()
      ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    return notes;
  }

  Future<PaperNote?> getForPaper(String paperId) async {
    final box = await _openBox();
    return box.get(paperId);
  }

  Future<bool> hasNote(String paperId) async {
    final note = await getForPaper(paperId);
    return note?.body.trim().isNotEmpty == true;
  }

  Future<PaperNote?> saveNote(Paper paper, String body) async {
    final normalizedBody = body.trim();
    if (normalizedBody.isEmpty) {
      await deleteNote(paper.id);
      return null;
    }

    final box = await _openBox();
    final now = DateTime.now();
    final existingNote = box.get(paper.id);
    final note =
        existingNote ??
        PaperNote(
          id: "note_${paper.id}",
          paperId: paper.id,
          paperTitle: paper.title,
          body: normalizedBody,
          createdAt: now,
          updatedAt: now,
          paper: paper,
        );

    note.body = normalizedBody;
    note.paper = paper;
    note.updatedAt = now;

    await box.put(paper.id, note);
    return note;
  }

  Future<PaperNote?> updateNote(PaperNote note, String body) async {
    final normalizedBody = body.trim();
    if (normalizedBody.isEmpty) {
      await deleteNote(note.paperId);
      return null;
    }

    final box = await _openBox();
    note.body = normalizedBody;
    note.updatedAt = DateTime.now();
    await box.put(note.paperId, note);
    return note;
  }

  Future<void> deleteNote(String paperId) async {
    final box = await _openBox();
    await box.delete(paperId);
  }
}
