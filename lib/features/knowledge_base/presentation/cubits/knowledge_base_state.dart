import '../../domain/entities/knowledge_note.dart';

enum KnowledgeBaseStatus { loading, ready, failure }

class KnowledgeBaseState {
  const KnowledgeBaseState({
    this.status = KnowledgeBaseStatus.loading,
    this.notes = const [],
    this.selectedNoteId,
    this.query = '',
    this.isSaving = false,
    this.message,
  });

  final KnowledgeBaseStatus status;
  final List<KnowledgeNote> notes;
  final String? selectedNoteId;
  final String query;
  final bool isSaving;
  final String? message;

  KnowledgeNote? get selectedNote {
    for (final note in notes) {
      if (note.id == selectedNoteId) return note;
    }
    return notes.isEmpty ? null : notes.first;
  }

  List<KnowledgeNote> get visibleNotes {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return notes;
    return notes
        .where((note) {
          return note.title.toLowerCase().contains(normalizedQuery) ||
              note.path.toLowerCase().contains(normalizedQuery) ||
              note.content.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  List<KnowledgeNote> get linkedNotes {
    final selected = selectedNote;
    if (selected == null) return const [];
    final links = selected.outgoingLinks.toSet();
    return notes.where((note) => links.contains(note.id)).toList();
  }

  List<KnowledgeNote> get backlinks {
    final selected = selectedNote;
    if (selected == null) return const [];
    return notes
        .where((note) {
          return note.outgoingLinks.contains(selected.id);
        })
        .toList(growable: false);
  }

  KnowledgeBaseState copyWith({
    KnowledgeBaseStatus? status,
    List<KnowledgeNote>? notes,
    String? selectedNoteId,
    bool clearSelectedNote = false,
    String? query,
    bool? isSaving,
    String? message,
  }) {
    return KnowledgeBaseState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      selectedNoteId: clearSelectedNote
          ? null
          : selectedNoteId ?? this.selectedNoteId,
      query: query ?? this.query,
      isSaving: isSaving ?? this.isSaving,
      message: message,
    );
  }
}
