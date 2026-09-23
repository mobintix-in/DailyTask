class NoteModel {
  final int? id;
  final String title;
  final String content;
  final String date; // YYYY-MM-DD
  final String colorHex;
  final String tags; // Comma separated tags e.g. "Idea, Work"
  final bool isPinned;
  final String updatedAt;

  NoteModel({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    this.colorHex = '#6C5CE7',
    this.tags = '',
    this.isPinned = false,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'date': date,
      'colorHex': colorHex,
      'tags': tags,
      'isPinned': isPinned ? 1 : 0,
      'updatedAt': updatedAt,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      date: map['date'] as String,
      colorHex: (map['colorHex'] as String?) ?? '#6C5CE7',
      tags: (map['tags'] as String?) ?? '',
      isPinned: (map['isPinned'] as int? ?? 0) == 1,
      updatedAt: map['updatedAt'] as String,
    );
  }

  NoteModel copyWith({
    int? id,
    String? title,
    String? content,
    String? date,
    String? colorHex,
    String? tags,
    bool? isPinned,
    String? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      colorHex: colorHex ?? this.colorHex,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
