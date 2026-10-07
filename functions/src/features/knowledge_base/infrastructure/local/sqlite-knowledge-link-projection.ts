import {and, eq, sql} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {knowledgeNotes, type KnowledgeNotes} from "../../../../db/schema.js";
import {knowledgeLinksFrom} from "../../domain/services/knowledge-link-extractor.js";

export async function knowledgeNotesWithLinks(database: RuntimeExecutor, teamId: string, knowledgeBaseId?: string) {
  const notes = await knowledgeRowsFor(database, teamId, knowledgeBaseId);
  const bases = notesByBase(notes);
  return notes.map((note) => ({...note, outgoingLinks: knowledgeLinksFrom(note.content, bases.get(note.knowledge_base_id) ?? [])}));
}

export async function knowledgeNoteWithLinks(database: RuntimeExecutor, teamId: string, knowledgeBaseId: string, id: string) {
  const notes = await knowledgeRowsFor(database, teamId, knowledgeBaseId);
  const note = notes.find((candidate) => candidate.id === id);
  return note === undefined ? null : {...note, outgoingLinks: knowledgeLinksFrom(note.content, notes)};
}

async function knowledgeRowsFor(database: RuntimeExecutor, teamId: string, knowledgeBaseId?: string) {
  const scope = knowledgeBaseId === undefined ? eq(knowledgeNotes.team_id, teamId) :
    and(eq(knowledgeNotes.team_id, teamId), eq(knowledgeNotes.knowledge_base_id, knowledgeBaseId));
  return database.select().from(knowledgeNotes).where(scope)
    .orderBy(sql`${knowledgeNotes.title} COLLATE NOCASE`, knowledgeNotes.id);
}

function notesByBase(notes: readonly KnowledgeNotes[]): Map<string, KnowledgeNotes[]> {
  const bases = new Map<string, KnowledgeNotes[]>();
  for (const note of notes) {
    const group = bases.get(note.knowledge_base_id) ?? [];
    group.push(note);
    bases.set(note.knowledge_base_id, group);
  }
  return bases;
}
