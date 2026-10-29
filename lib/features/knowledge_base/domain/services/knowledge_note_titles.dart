import '../entities/knowledge_note.dart';

/// Titel sind pro Wissensbasis eindeutig, ohne Unterschied von Groß/Klein —
/// so lösen auch `[[Titel]]`-Links auf. Dieselbe Regel prüft die Runtime.
bool sameKnowledgeNoteTitle(String left, String right) =>
    left.trim().toLowerCase() == right.trim().toLowerCase();

/// Ob eine andere Notiz als [exceptNoteId] den Titel schon trägt.
bool isKnowledgeNoteTitleTaken(
  List<KnowledgeNote> notes,
  String title, {
  String? exceptNoteId,
}) => notes.any(
  (note) =>
      note.id != exceptNoteId && sameKnowledgeNoteTitle(note.title, title),
);
