import 'package:arxiv/components/paper_note_card.dart';
import 'package:arxiv/models/paper_note.dart';
import 'package:arxiv/pages/paper_detail_page.dart';
import 'package:arxiv/services/paper_notes_store.dart';
import 'package:flutter/material.dart';

class PaperNotesPage extends StatefulWidget {
  const PaperNotesPage({
    super.key,
    required this.downloadPaper,
    required this.parseAndLaunchURL,
    required this.onSearchQuerySelected,
  });

  final Function downloadPaper;
  final Function parseAndLaunchURL;
  final Future<void> Function(String query) onSearchQuerySelected;

  @override
  State<PaperNotesPage> createState() => _PaperNotesPageState();
}

class _PaperNotesPageState extends State<PaperNotesPage> {
  final PaperNotesStore _notesStore = PaperNotesStore();

  List<PaperNote> _notes = [];
  bool _isLoadingNotes = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await _notesStore.loadNotes();
    if (!mounted) return;

    setState(() {
      _notes = notes;
      _isLoadingNotes = false;
    });
  }

  Future<void> _confirmDeleteNote(PaperNote note) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete note?"),
        content: Text(
          "This will permanently delete the note for \"${note.paperTitle}\".",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    await _notesStore.deleteNote(note.paperId);
    await _loadNotes();
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Note deleted")));
  }

  Future<PaperNote?> _saveInlineNote(PaperNote note, String body) async {
    final updatedNote = await _notesStore.updateNote(note, body);
    await _loadNotes();
    if (!mounted) return updatedNote;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(updatedNote == null ? "Note cleared" : "Note saved"),
      ),
    );
    return updatedNote;
  }

  Future<void> _openPaperDetails(PaperNote note) async {
    final paper = note.paper;
    if (paper == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Paper details are unavailable for this older note."),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaperDetailPage(
          paper: paper,
          downloadPaper: widget.downloadPaper,
          parseAndLaunchURL: widget.parseAndLaunchURL,
          onSearchQuerySelected: widget.onSearchQuerySelected,
        ),
      ),
    );
    await _loadNotes();
  }

  Widget _buildNotesList() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoadingNotes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notes.isEmpty) {
      return Center(
        child: Text(
          "No paper notes yet",
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16.0),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotes,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];

          return PaperNoteCard(
            note: note,
            onPaperTap: () => _openPaperDetails(note),
            allowInlineView: true,
            allowInlineEdit: true,
            onSave: (body) => _saveInlineNote(note, body),
            onDelete: () => _confirmDeleteNote(note),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paper Notes")),
      body: _buildNotesList(),
    );
  }
}
