import 'dart:io';

import 'package:arxiv/models/paper.dart';
import 'package:arxiv/models/paper_note.dart';
import 'package:arxiv/services/paper_notes_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDirectory;

  setUpAll(() {
    tempDirectory = Directory.systemTemp.createTempSync(
      'paper_notes_store_test_',
    );
    Hive.init(tempDirectory.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PaperAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(PaperNoteAdapter());
    }
  });

  tearDown(() async {
    if (Hive.isBoxOpen(PaperNotesStore.boxName)) {
      await Hive.box<PaperNote>(PaperNotesStore.boxName).close();
    }
    try {
      await Hive.deleteBoxFromDisk(PaperNotesStore.boxName);
    } catch (_) {
      // The box may not exist if a test fails before opening it.
    }
  });

  tearDownAll(() async {
    await Hive.close();
    tempDirectory.deleteSync(recursive: true);
  });

  test('PaperNotesStore saves, updates, and clears a paper note', () async {
    final paper = Paper(
      '1234.56789v1',
      'A note-worthy paper',
      'A sample abstract.',
      '2026-01-02',
      'Ada Lovelace',
    );
    final store = PaperNotesStore();

    final savedNote = await store.saveNote(paper, '  First note  ');
    expect(savedNote?.paperId, paper.id);
    expect(savedNote?.paperTitle, paper.title);
    expect(savedNote?.paper?.id, paper.id);
    expect(savedNote?.body, 'First note');
    expect(await store.hasNote(paper.id), isTrue);

    final loadedNote = await store.getForPaper(paper.id);
    expect(loadedNote?.body, 'First note');

    final updatedNote = await store.saveNote(paper, 'Second note');
    expect(updatedNote?.id, savedNote?.id);
    expect(updatedNote?.body, 'Second note');

    final notes = await store.loadNotes();
    expect(notes, hasLength(1));
    expect(notes.first.paperId, paper.id);

    final editedNote = await store.updateNote(updatedNote!, 'Edited note');
    expect(editedNote?.body, 'Edited note');

    await store.saveNote(paper, '   ');
    expect(await store.getForPaper(paper.id), isNull);
    expect(await store.hasNote(paper.id), isFalse);
  });
}
