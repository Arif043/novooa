/**
 * Titel sind pro Wissensbasis eindeutig, ohne Unterschied von Groß/Klein — so lösen auch
 * `[[Titel]]`-Links auf, und Workspace-Dateien heißen wie der Titel.
 */
export function sameKnowledgeNoteTitle(left: string, right: string): boolean {
  return normalizedTitle(left) === normalizedTitle(right);
}

/** Findet die Notiz, die einen Titel schon trägt; die Notiz selbst zählt beim Umbenennen nicht. */
export function knowledgeNoteWithTitle<T extends {id: string; title: string}>(
  notes: readonly T[],
  title: string,
  exceptNoteId?: string,
): T | undefined {
  return notes.find((note) => note.id !== exceptNoteId && sameKnowledgeNoteTitle(note.title, title));
}

function normalizedTitle(title: string): string {
  return title.trim().toLowerCase();
}
