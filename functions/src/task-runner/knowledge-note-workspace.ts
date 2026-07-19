import {mkdir, writeFile} from "node:fs/promises";
import path from "node:path";

import {type KnowledgeAttachment} from "./task-definition.js";
import {
  type KnowledgeBaseStore,
  type KnowledgeNoteDocument,
} from "../domain/repositories/knowledge-base-store.js";

const maxNotes = 50;
const maxDepth = 5;

export type PreparedKnowledgeAttachment = KnowledgeAttachment & {
  filename: string;
};

export async function prepareKnowledgeFiles(
  rootDirectory: string,
  teamId: string,
  attachments: KnowledgeAttachment[],
  store: KnowledgeBaseStore,
): Promise<PreparedKnowledgeAttachment[]> {
  if (attachments.length === 0) return [];
  const directory = path.join(rootDirectory, "knowledge");
  await mkdir(directory, {recursive: true});
  const resolver = new KnowledgeNoteResolver(teamId, store);
  const notes = await resolver.resolveAll(attachments);
  const preparedNotes = notes.map(preparedNote);
  await writeKnowledgeManifest(directory, preparedNotes);
  await Promise.all(preparedNotes.map((note) => writeNote(directory, note)));
  return preparedNotes;
}

class KnowledgeNoteResolver {
  constructor(
    private readonly teamId: string,
    private readonly store: KnowledgeBaseStore,
  ) {}

  async resolveAll(
    attachments: KnowledgeAttachment[],
  ): Promise<KnowledgeNoteDocument[]> {
    const notes: KnowledgeNoteDocument[] = [];
    const visited = new Set<string>();
    for (const attachment of attachments) {
      await this.resolveAttachment(attachment, notes, visited, 0);
    }
    return notes.slice(0, maxNotes);
  }

  private async resolveAttachment(
    attachment: KnowledgeAttachment,
    notes: KnowledgeNoteDocument[],
    visited: Set<string>,
    depth: number,
  ): Promise<void> {
    if (depth > maxDepth || notes.length >= maxNotes) return;
    const key = `${attachment.knowledgeBaseId}/${attachment.noteId}`;
    if (visited.has(key)) return;
    visited.add(key);
    const note = await this.store.loadNote(this.teamId, attachment);
    notes.push(note);
    if (note.type !== "moc") return;
    for (const noteId of note.outgoingLinks) {
      await this.resolveAttachment({...note, noteId}, notes, visited, depth + 1);
    }
  }
}

async function writeNote(
  directory: string,
  note: PreparedKnowledgeAttachment & {content: string},
): Promise<PreparedKnowledgeAttachment> {
  await writeFile(path.join(directory, path.basename(note.filename)), note.content);
  return note;
}

async function writeKnowledgeManifest(
  directory: string,
  notes: PreparedKnowledgeAttachment[],
): Promise<void> {
  const manifest = notes.map((note) => ({
    noteId: note.noteId,
    title: note.title,
    type: note.type,
    path: note.filename,
    originalPath: note.path,
  }));
  await writeFile(
    path.join(directory, "manifest.json"),
    JSON.stringify(manifest, null, 2),
  );
}

function preparedNote(
  note: KnowledgeNoteDocument,
  index: number,
): PreparedKnowledgeAttachment & {content: string} {
  return {
    ...note,
    filename: `knowledge/${safeFilename(note.path || note.title, index)}`,
  };
}

function safeFilename(displayName: string, index: number): string {
  const fallback = `notiz-${index + 1}.md`;
  const normalized = displayName.trim() || fallback;
  const safeName = normalized.replace(/[^a-zA-Z0-9._-]+/g, "_");
  return `${index + 1}-${safeName.slice(0, 120)}`;
}
