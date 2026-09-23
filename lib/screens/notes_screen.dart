import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<NoteModel> _notes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = _searchQuery.isEmpty
        ? await DatabaseService.instance.getAllNotes()
        : await DatabaseService.instance.searchNotes(_searchQuery);

    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _loadNotes();
  }

  Future<void> _togglePin(NoteModel note) async {
    final updated = note.copyWith(
      isPinned: !note.isPinned,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await DatabaseService.instance.updateNote(updated);
    _loadNotes();
  }

  Future<void> _deleteNote(NoteModel note) async {
    if (note.id != null) {
      await DatabaseService.instance.deleteNote(note.id!);
      _loadNotes();
      if (mounted) {
        AppToast.info(
          context,
          'Deleted "${note.title}"',
          icon: Icons.delete_outline_rounded,
          actionLabel: 'Undo',
          onAction: () async {
            await DatabaseService.instance.insertNote(note);
            _loadNotes();
          },
        );
      }
    }
  }

  void _openNoteEditor([NoteModel? note]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _NoteEditorScreen(
          note: note,
          onSaved: _loadNotes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pinnedNotes = _notes.where((n) => n.isPinned).toList();
    final regularNotes = _notes.where((n) => !n.isPinned).toList();

    return Scaffold(
      backgroundColor: AppTheme.groupedBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.groupedBackground,
        title: const Text(
          'Notes',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.8,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
            onPressed: _loadNotes,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Apple Notes Style Rounded Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE3E3E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel, color: AppTheme.textSecondary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Notes List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _notes.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        backgroundColor: Colors.white,
                        onRefresh: _loadNotes,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          children: [
                            if (pinnedNotes.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.push_pin_rounded, size: 14, color: AppTheme.accentAmber),
                                    SizedBox(width: 6),
                                    Text(
                                      'PINNED',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.accentAmber,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...pinnedNotes.map((n) => _buildNoteCard(n)),
                              const SizedBox(height: 16),
                            ],

                            if (regularNotes.isNotEmpty) ...[
                              if (pinnedNotes.isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 8),
                                  child: Text(
                                    'NOTES',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ...regularNotes.map((n) => _buildNoteCard(n)),
                            ],
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'notes_fab',
        onPressed: () => _openNoteEditor(),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.edit_note_rounded, size: 24),
        label: const Text(
          'New Note',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2),
        ),
      ),
    );
  }

  Widget _buildNoteCard(NoteModel note) {
    Color cardAccentColor;
    try {
      cardAccentColor = Color(int.parse(note.colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      cardAccentColor = AppTheme.primary;
    }

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.accentCoral,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
      ),
      onDismissed: (_) => _deleteNote(note),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.surfaceBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openNoteEditor(note),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(top: 5, right: 10),
                      decoration: BoxDecoration(
                        color: cardAccentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        note.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                        size: 18,
                        color: note.isPinned ? AppTheme.accentAmber : AppTheme.textSecondary,
                      ),
                      onPressed: () => _togglePin(note),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (note.content.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    note.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF3C3C43),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (note.tags.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        children: note.tags.split(',').map((t) {
                          final tag = t.trim();
                          if (tag.isEmpty) return const SizedBox();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    else
                      const SizedBox(),
                    Text(
                      note.date,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceElevated,
            ),
            child: const Icon(
              Icons.note_alt_outlined,
              size: 44,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Notes Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap "New Note" to capture your thoughts.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;
  final VoidCallback onSaved;

  const _NoteEditorScreen({this.note, required this.onSaved});

  @override
  State<_NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<_NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedColor;
  bool _isPinned = false;

  final List<String> _colors = [
    '#007AFF', // Apple Blue
    '#34C759', // Apple Green
    '#FF9500', // Apple Orange
    '#FF3B30', // Apple Red
    '#AF52DE', // Apple Purple
    '#5856D6', // Apple Indigo
  ];

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    _titleController = TextEditingController(text: n?.title ?? '');
    _contentController = TextEditingController(text: n?.content ?? '');
    _selectedColor = n?.colorHex ?? '#007AFF';
    _isPinned = n?.isPinned ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppToast.warning(context, 'Please enter a note title');
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final noteToSave = NoteModel(
      id: widget.note?.id,
      title: title,
      content: _contentController.text.trim(),
      date: widget.note?.date ?? dateStr,
      colorHex: _selectedColor,
      tags: widget.note?.tags ?? '',
      isPinned: _isPinned,
      updatedAt: DateTime.now().toIso8601String(),
    );

    if (widget.note == null) {
      await DatabaseService.instance.insertNote(noteToSave);
    } else {
      await DatabaseService.instance.updateNote(noteToSave);
    }

    widget.onSaved();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Row(
            children: [
              Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppTheme.primary),
            ],
          ),
        ),
        title: Text(
          widget.note == null ? 'New Note' : 'Edit Note',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: _isPinned ? AppTheme.accentAmber : AppTheme.textSecondary,
            ),
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          TextButton(
            onPressed: _save,
            child: const Text(
              'Done',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Apple Color Palette Swatches
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _colors.map((hex) {
                  final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                  final isSel = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSel
                            ? Border.all(color: Colors.black, width: 2.5)
                            : Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1),
                      ),
                      child: isSel
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Title Field
            TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.6,
              ),
              decoration: const InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondary,
                  letterSpacing: -0.6,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const Divider(color: AppTheme.surfaceBorder, height: 28),

            // Content Body Field
            TextField(
              controller: _contentController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: AppTheme.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Start typing your note...',
                hintStyle: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
