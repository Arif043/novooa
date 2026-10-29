import {type KnowledgeNote} from "../entities/knowledge-note.js";
import {knowledgeLinksFrom} from "./knowledge-link-extractor.js";

export type KnowledgeNoteReference = {id: string; title: string};

export type KnowledgeNoteNeighbours = {
  links: KnowledgeNoteReference[];
  backlinks: KnowledgeNoteReference[];
};

/** Nachbarn im Zettelkasten: worauf eine Notiz verlinkt und welche Notizen auf sie verlinken. */
export function knowledgeNoteNeighbours(
  note: KnowledgeNote,
  notes: readonly KnowledgeNote[],
): KnowledgeNoteNeighbours {
  const others = notes.filter((candidate) => candidate.id !== note.id);
  const linkedIds = new Set(knowledgeLinksFrom(note.content, others));
  return {
    links: others.filter((candidate) => linkedIds.has(candidate.id)).map(referenceTo),
    backlinks: others
      .filter((candidate) => knowledgeLinksFrom(candidate.content, [note]).length > 0)
      .map(referenceTo),
  };
}

function referenceTo(note: KnowledgeNote): KnowledgeNoteReference {
  return {id: note.id, title: note.title};
}
