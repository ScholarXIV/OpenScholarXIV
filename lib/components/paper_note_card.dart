import 'package:arxiv/models/paper_note.dart';
import 'package:arxiv/theme/app_theme.dart';
import 'package:flutter/material.dart';

class PaperNoteCard extends StatefulWidget {
  const PaperNoteCard({
    super.key,
    required this.note,
    this.onPaperTap,
    this.onView,
    this.onSave,
    this.onDelete,
    this.showFullBody = false,
    this.allowInlineView = false,
    this.allowInlineEdit = false,
    this.showPaperHeader = true,
    this.plainBody = false,
  });

  final PaperNote note;
  final VoidCallback? onPaperTap;
  final VoidCallback? onView;
  final Future<PaperNote?> Function(String body)? onSave;
  final VoidCallback? onDelete;
  final bool showFullBody;
  final bool allowInlineView;
  final bool allowInlineEdit;
  final bool showPaperHeader;
  final bool plainBody;

  @override
  State<PaperNoteCard> createState() => _PaperNoteCardState();
}

class _PaperNoteCardState extends State<PaperNoteCard> {
  late final TextEditingController _notesController;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.note.body);
  }

  @override
  void didUpdateWidget(covariant PaperNoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.body != widget.note.body && !_isEditing) {
      _notesController.text = widget.note.body;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _notesController.text = widget.note.body;
      _isEditing = true;
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _cancelEditing() {
    setState(() {
      _notesController.text = widget.note.body;
      _isEditing = false;
    });
  }

  Future<void> _saveInlineEdit() async {
    final onSave = widget.onSave;
    if (onSave == null) return;

    setState(() {
      _isSaving = true;
    });

    await onSave(_notesController.text);
    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _isEditing = false;
    });
  }

  String _formatStoredDate(DateTime date) {
    final localDate = date.toLocal();
    return "${localDate.year}-${_twoDigits(localDate.month)}-${_twoDigits(localDate.day)} "
        "${_twoDigits(localDate.hour)}:${_twoDigits(localDate.minute)}";
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, "0");
  }

  Widget _buildNoteBodyContent(ColorScheme colorScheme) {
    if (_isEditing) {
      return TextField(
        controller: _notesController,
        autofocus: true,
        minLines: 5,
        maxLines: 10,
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
      );
    }

    if (widget.showFullBody || _isExpanded) {
      return SelectableText(
        widget.note.body,
        style: TextStyle(color: colorScheme.onSurface, fontSize: 14.0),
      );
    }

    return Text(
      widget.note.body,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 14.0),
    );
  }

  Widget _buildNoteBody(ColorScheme colorScheme) {
    if (widget.plainBody) {
      return _buildNoteBodyContent(colorScheme);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: _buildNoteBodyContent(colorScheme),
    );
  }

  Widget _buildActions() {
    if (_isEditing) {
      return Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: [
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveInlineEdit,
            icon: _isSaving
                ? const SizedBox(
                    width: 16.0,
                    height: 16.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text("Save"),
          ),
          TextButton(
            onPressed: _isSaving ? null : _cancelEditing,
            child: const Text("Cancel"),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        if (widget.allowInlineView && !widget.showFullBody)
          OutlinedButton.icon(
            onPressed: _toggleExpanded,
            icon: Icon(
              _isExpanded
                  ? Icons.unfold_less_outlined
                  : Icons.visibility_outlined,
            ),
            label: Text(_isExpanded ? "Collapse" : "View"),
          )
        else if (widget.onView != null)
          OutlinedButton.icon(
            onPressed: widget.onView,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text("View"),
          ),
        if (widget.allowInlineEdit && widget.onSave != null)
          IconButton(
            tooltip: "Edit",
            onPressed: _startEditing,
            icon: const Icon(Icons.edit_outlined),
          ),
        if (widget.onDelete != null)
          IconButton(
            tooltip: "Delete",
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final paperHeader = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.sticky_note_2_outlined,
          color: colorScheme.primary,
          size: 20.0,
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.note.paperTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 2.0,
                children: [
                  Text(
                    "Paper: ${widget.note.paperId}",
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12.0,
                    ),
                  ),
                  Text(
                    "Updated ${_formatStoredDate(widget.note.updatedAt)}",
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.onPaperTap != null)
          Icon(
            Icons.chevron_right,
            color: colorScheme.onSurfaceVariant,
            size: 20.0,
          ),
      ],
    );

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
          if (widget.showPaperHeader) ...[
            if (widget.onPaperTap == null)
              paperHeader
            else
              InkWell(
                borderRadius: BorderRadius.circular(8.0),
                onTap: widget.onPaperTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: paperHeader,
                ),
              ),
            const SizedBox(height: 8.0),
          ],
          _buildNoteBody(colorScheme),
          const SizedBox(height: 8.0),
          _buildActions(),
        ],
      ),
    );
  }
}
