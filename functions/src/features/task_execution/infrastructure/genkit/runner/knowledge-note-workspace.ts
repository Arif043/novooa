import {mkdir, writeFile} from "node:fs/promises";
import path from "node:path";

import {type KnowledgeAttachment} from "./task-definition.js";
import {
  type KnowledgeBaseStore,
  type KnowledgeNoteDocument,
} from "../../../../knowledge_base/domain/repositories/knowledge-base-store.js";
import {knowledgeNoteFilenames} from "./knowledge-note-filenames.js";

const maxNotes = 50;
const maxDepth = 5;

export type PreparedKnowledgeAttachment = KnowledgeAttachment & {
  filename: string;
  isDirectAttachment: boolean;
  /** Abstand zum Anhang: 0 für angehängte Notizen, 1 für deren Links usw. */
  depth: number;
  /** Titel der Notizen im Workspace, auf die diese Notiz verlinkt. */
  linkedTitles: string[];
};

type ResolvedKnowledgeNote = KnowledgeNoteDocument & {
  isDirectAttachment: boolean;
  depth: number;
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
  const preparedNotes = preparedNotesFrom(notes);
  await writeKnowledgeManifest(directory, preparedNotes);
  await Promise.all(preparedNotes.map((note) => writeNote(directory, note)));
  return preparedNotes;
}

type PendingKnowledgeNote = {
  attachment: KnowledgeAttachment;
  depth: number;
  isDirectAttachment: boolean;
};

/**
 * Sammelt die angehängten Notizen und alle ausgehend erreichbaren Notizen
 * Ebene für Ebene (Breitensuche): Erst alle direkten Anhänge, dann deren Links,
 * dann die Links der Links. So verdrängt ein tiefer Zweig bei erreichtem Limit
 * keine näher liegenden Notizen.
 */
class KnowledgeNoteResolver {
  constructor(
    private readonly teamId: string,
    private readonly store: KnowledgeBaseStore,
  ) {}

  async resolveAll(
    attachments: KnowledgeAttachment[],
  ): Promise<ResolvedKnowledgeNote[]> {
    const notes: ResolvedKnowledgeNote[] = [];
    const queued = new Set<string>();
    const queue: PendingKnowledgeNote[] = [];
    for (const attachment of attachments) {
      this.enqueue(queue, queued, {attachment, depth: 0, isDirectAttachment: true});
    }
    for (let next = queue.shift(); next !== undefined && notes.length < maxNotes; next = queue.shift()) {
      const note = await this.store.loadNote(this.teamId, next.attachment);
      notes.push({...note, isDirectAttachment: next.isDirectAttachment, depth: next.depth});
      this.enqueueLinks(queue, queued, note, next.depth + 1);
    }
    return notes;
  }

  private enqueueLinks(
    queue: PendingKnowledgeNote[],
    queued: Set<string>,
    note: KnowledgeNoteDocument,
    depth: number,
  ): void {
    if (depth > maxDepth) return;
    for (const noteId of note.outgoingLinks) {
      this.enqueue(queue, queued, {attachment: {...note, noteId}, depth, isDirectAttachment: false});
    }
  }

  /** Jede Notiz wird nur einmal eingereiht; direkte Anhänge stehen zuerst in der Schlange und behalten so ihre Markierung. */
  private enqueue(
    queue: PendingKnowledgeNote[],
    queued: Set<string>,
    pending: PendingKnowledgeNote,
  ): void {
    const key = `${pending.attachment.knowledgeBaseId}/${pending.attachment.noteId}`;
    if (queued.has(key)) return;
    queued.add(key);
    queue.push(pending);
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
    isDirectAttachment: note.isDirectAttachment,
    path: note.filename,
    originalPath: note.path,
  }));
  await writeFile(
    path.join(directory, "manifest.json"),
    JSON.stringify(manifest, null, 2),
  );
}

function preparedNotesFrom(notes: ResolvedKnowledgeNote[]): (PreparedKnowledgeAttachment & {content: string})[] {
  const filenames = knowledgeNoteFilenames(notes);
  const titles = new Map(notes.map((note) => [note.noteId, note.title]));
  return notes.map(({outgoingLinks, ...note}) => ({
    ...note,
    filename: filenames.get(note.noteId)!,
    linkedTitles: outgoingLinks.flatMap((noteId) => titles.get(noteId) ?? []),
  }));
}
