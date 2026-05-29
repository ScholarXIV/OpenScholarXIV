import 'package:arxiv/components/each_paper_card.dart';
import 'package:arxiv/components/paper_note_card.dart';
import 'package:arxiv/models/paper.dart';
import 'package:arxiv/models/paper_note.dart';
import 'package:arxiv/services/author_parser.dart';
import 'package:arxiv/services/citation_formatter.dart';
import 'package:arxiv/services/paper_notes_store.dart';
import 'package:arxiv/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _CitationMenuAction { bibtex, apa, link }

class PaperDetailPage extends StatefulWidget {
  const PaperDetailPage({
    super.key,
    required this.paper,
    required this.downloadPaper,
    required this.parseAndLaunchURL,
    required this.onSearchQuerySelected,
  });

  final Paper paper;
  final Function downloadPaper;
  final Function parseAndLaunchURL;
  final Future<void> Function(String query) onSearchQuerySelected;

  @override
  State<PaperDetailPage> createState() => _PaperDetailPageState();
}

class _PaperDetailPageState extends State<PaperDetailPage> {
  final PaperNotesStore _notesStore = PaperNotesStore();
  final TextEditingController _notesController = TextEditingController();

  PaperNote? _note;
  bool _isLoadingNote = true;
  bool _isSavingNote = false;
  bool _hasUnsavedChanges = false;
  bool _isApplyingStoredNote = false;
  bool _isEditingNote = true;
  int _notesRefreshToken = 0;

  @override
  void initState() {
    super.initState();
    _notesController.addListener(_handleNotesChanged);
    _loadNote();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    final note = await _notesStore.getForPaper(widget.paper.id);
    if (!mounted) return;

    _isApplyingStoredNote = true;
    _notesController.text = note?.body ?? "";
    _isApplyingStoredNote = false;

    setState(() {
      _note = note;
      _isLoadingNote = false;
      _hasUnsavedChanges = false;
      _isEditingNote = note == null;
    });
  }

  void _handleNotesChanged() {
    if (_isApplyingStoredNote || _isLoadingNote) return;
    if (_hasUnsavedChanges) return;

    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveNote() async {
    setState(() {
      _isSavingNote = true;
    });

    final note = await _notesStore.saveNote(
      widget.paper,
      _notesController.text,
    );
    if (!mounted) return;

    setState(() {
      _note = note;
      _isSavingNote = false;
      _hasUnsavedChanges = false;
      _isEditingNote = note == null;
      _notesRefreshToken++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(note == null ? "Note cleared" : "Note saved")),
    );
  }

  Future<void> _deleteNote() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete note?"),
        content: const Text("This will permanently delete this paper note."),
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

    await _notesStore.deleteNote(widget.paper.id);
    if (!mounted) return;

    _isApplyingStoredNote = true;
    _notesController.clear();
    _isApplyingStoredNote = false;

    setState(() {
      _note = null;
      _hasUnsavedChanges = false;
      _isEditingNote = true;
      _notesRefreshToken++;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Note deleted")));
  }

  Future<void> _copyCitation(_CitationMenuAction action) async {
    final citation = switch (action) {
      _CitationMenuAction.bibtex => CitationFormatter.bibtex(widget.paper),
      _CitationMenuAction.apa => CitationFormatter.apa(widget.paper),
      _CitationMenuAction.link => CitationFormatter.abstractUrl(widget.paper),
    };

    final label = switch (action) {
      _CitationMenuAction.bibtex => "BibTeX",
      _CitationMenuAction.apa => "APA citation",
      _CitationMenuAction.link => "arXiv link",
    };

    await Clipboard.setData(ClipboardData(text: citation));
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("$label copied")));
  }

  List<PopupMenuEntry<_CitationMenuAction>> _buildCitationMenuItems() {
    return const [
      PopupMenuItem(
        value: _CitationMenuAction.bibtex,
        child: Text("Copy BibTeX"),
      ),
      PopupMenuItem(value: _CitationMenuAction.apa, child: Text("Copy APA")),
      PopupMenuItem(
        value: _CitationMenuAction.link,
        child: Text("Copy arXiv Link"),
      ),
    ];
  }

  Future<void> _searchAuthor(String author) async {
    await widget.onSearchQuerySelected(AuthorParser.authorQueryFor(author));
    if (!mounted) return;

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Widget _buildAuthorChips() {
    final authors = AuthorParser.authorsForPaper(widget.paper);
    if (authors.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 8.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: subtleSurfaceColor(colorScheme),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Authors",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: authors
                .map(
                  (author) => ActionChip(
                    label: Text(author),
                    avatar: const Icon(Icons.person_search_outlined, size: 18),
                    onPressed: () => _searchAuthor(author),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  List<String> get _otherCategories {
    return widget.paper.categories
        .where((category) => category != widget.paper.primaryCategory)
        .toList();
  }

  String _formatStoredDate(DateTime date) {
    final localDate = date.toLocal();
    return "${localDate.year}-${_twoDigits(localDate.month)}-${_twoDigits(localDate.day)} "
        "${_twoDigits(localDate.hour)}:${_twoDigits(localDate.minute)}";
  }

  String _formatMetadataDate(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.length >= 10) {
      return trimmedValue.substring(0, 10);
    }
    return trimmedValue;
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, "0");
  }

  Widget _buildMetadataPanel() {
    final colorScheme = Theme.of(context).colorScheme;
    final rows = <Widget>[
      if (widget.paper.updatedAt.trim().isNotEmpty)
        _MetadataValueRow(
          label: "Updated",
          value: _formatMetadataDate(widget.paper.updatedAt),
        ),
      if (_otherCategories.isNotEmpty)
        _MetadataChipRow(label: "Other categories", values: _otherCategories),
      if (widget.paper.abstractUrl.trim().isNotEmpty)
        _MetadataValueRow(
          label: "Abstract link",
          value: widget.paper.abstractUrl,
        ),
      if (widget.paper.pdfUrl.trim().isNotEmpty)
        _MetadataValueRow(label: "PDF link", value: widget.paper.pdfUrl),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 8.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: subtleSurfaceColor(colorScheme),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "More Metadata",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10.0),
          if (rows.isEmpty)
            Text(
              "No additional metadata available.",
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            )
          else
            ...rows,
        ],
      ),
    );
  }

  Widget _buildNotesEditor() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 24.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: subtleSurfaceColor(colorScheme),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: _isLoadingNote
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Notes",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (_hasUnsavedChanges)
                      Text(
                        "Unsaved changes",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12.0,
                        ),
                      )
                    else if (_note != null)
                      Text(
                        "Last saved ${_formatStoredDate(_note!.updatedAt)}",
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12.0,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10.0),
                TextField(
                  controller: _notesController,
                  minLines: 8,
                  maxLines: 14,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: "Write your notes about this paper...",
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isSavingNote ? null : _saveNote,
                      icon: _isSavingNote
                          ? SizedBox(
                              width: 16.0,
                              height: 16.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text("Save"),
                    ),
                    const SizedBox(width: 8.0),
                    if (_note != null)
                      TextButton.icon(
                        onPressed: _isSavingNote ? null : _deleteNote,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text("Delete"),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSavedNote() {
    final note = _note;
    if (note == null) return _buildNotesEditor();

    return PaperNoteCard(
      note: note,
      showFullBody: true,
      showPaperHeader: false,
      plainBody: true,
      allowInlineEdit: true,
      onSave: (body) async {
        final updatedNote = await _notesStore.saveNote(widget.paper, body);
        if (!mounted) return updatedNote;

        setState(() {
          _note = updatedNote;
          _isEditingNote = updatedNote == null;
          _notesRefreshToken++;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updatedNote == null ? "Note cleared" : "Note saved"),
          ),
        );
        return updatedNote;
      },
      onDelete: _deleteNote,
    );
  }

  Widget _buildNotesSection() {
    if (_isLoadingNote) return _buildNotesEditor();
    if (_note != null && !_isEditingNote) return _buildSavedNote();
    return _buildNotesEditor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paper Details"),
        actions: [
          PopupMenuButton<_CitationMenuAction>(
            tooltip: "Copy citation",
            icon: const Icon(Icons.format_quote_outlined),
            onSelected: _copyCitation,
            itemBuilder: (context) => _buildCitationMenuItems(),
          ),
        ],
      ),
      body: ListView(
        children: [
          EachPaperCard(
            eachPaper: widget.paper,
            downloadPaper: widget.downloadPaper,
            parseAndLaunchURL: widget.parseAndLaunchURL,
            isBookmarked: false,
            notesRefreshToken: _notesRefreshToken,
          ),
          _buildAuthorChips(),
          _buildMetadataPanel(),
          _buildNotesSection(),
        ],
      ),
    );
  }
}

class _MetadataValueRow extends StatelessWidget {
  const _MetadataValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2.0),
          SelectableText(
            value,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 13.0),
          ),
        ],
      ),
    );
  }
}

class _MetadataChipRow extends StatelessWidget {
  const _MetadataChipRow({required this.label, required this.values});

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6.0),
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: values
                .map(
                  (value) => Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(value),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
