import {type KnowledgeNote} from "../entities/knowledge-note.js";
import {knowledgeLinksFrom} from "./knowledge-link-extractor.js";

export type KnowledgeNoteOverviewEntry = {
  id: string;
  title: string;
  links: number;
  backlinks: number;
};

/**
 * Der ganze Zettelkasten ohne Inhalte: je Notiz, wie viele Notizen sie verlinkt und wie viele
 * auf sie verlinken. Null Rückverweise kennzeichnet eine Waise.
 */
export function knowledgeNoteOverview(notes: readonly KnowledgeNote[]): KnowledgeNoteOverviewEntry[] {
  const linksById = new Map(notes.map((note) => [note.id, outgoingLinksOf(note, notes)]));
  const backlinks = new Map<string, number>();
  for (const targets of linksById.values()) {
    for (const target of targets) backlinks.set(target, (backlinks.get(target) ?? 0) + 1);
  }
  return notes.map((note) => ({
    id: note.id,
    title: note.title,
    links: linksById.get(note.id)?.size ?? 0,
    backlinks: backlinks.get(note.id) ?? 0,
  }));
}

function outgoingLinksOf(note: KnowledgeNote, notes: readonly KnowledgeNote[]): Set<string> {
  const others = notes.filter((candidate) => candidate.id !== note.id);
  return new Set(knowledgeLinksFrom(note.content, others));
}
