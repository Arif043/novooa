import {type KnowledgeNote} from "../entities/knowledge-note.js";

/** Treffer im Titel zählen mehr als im Pfad, beide mehr als im Inhalt; sonst bleibt die Reihenfolge. */
export function searchKnowledgeNotes(
  notes: readonly KnowledgeNote[],
  query: string,
  limit: number,
): KnowledgeNote[] {
  const normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.length === 0) return notes.slice(0, limit);
  return notes
    .map((note, position) => ({note, position, rank: rankOf(note, normalizedQuery)}))
    .filter((candidate) => candidate.rank !== null)
    .sort((left, right) => (left.rank! - right.rank!) || (left.position - right.position))
    .slice(0, limit)
    .map((candidate) => candidate.note);
}

function rankOf(note: KnowledgeNote, query: string): number | null {
  const fields = [note.title, note.path, note.content];
  const index = fields.findIndex((field) => field.toLowerCase().includes(query));
  return index === -1 ? null : index;
}
