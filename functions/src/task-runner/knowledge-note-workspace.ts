import {mkdir, writeFile} from "node:fs/promises";
import path from "node:path";
import {getFirestore, type DocumentData} from "firebase-admin/firestore";

import {type KnowledgeAttachment} from "./task-definition.js";

const maxNotes = 50;
const maxDepth = 5;

export type PreparedKnowledgeAttachment = KnowledgeAttachment & {
  filename: string;
};

type KnowledgeNoteDocument = KnowledgeAttachment & {
  content: string;
  outgoingLinks: string[];
};

export async function prepareKnowledgeFiles(
  rootDirectory: string,
  teamId: string,
  attachments: KnowledgeAttachment[],
): Promise<PreparedKnowledgeAttachment[]> {
  if (attachments.length === 0) return [];
  const directory = path.join(rootDirectory, "knowledge");
  await mkdir(directory, {recursive: true});
  const resolver = new KnowledgeNoteResolver(teamId);
  const notes = await resolver.resolveAll(attachments);
  const preparedNotes = notes.map(preparedNote);
  await writeKnowledgeManifest(directory, preparedNotes);
  await Promise.all(preparedNotes.map((note) => writeNote(directory, note)));
  return preparedNotes;
}

class KnowledgeNoteResolver {
  constructor(private readonly teamId: string) {}

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
    const note = await this.fetchNote(attachment);
    notes.push(note);
    if (note.type !== "moc") return;
    for (const noteId of note.outgoingLinks) {
      await this.resolveAttachment({...note, noteId}, notes, visited, depth + 1);
    }
  }

  private async fetchNote(
    attachment: KnowledgeAttachment,
  ): Promise<KnowledgeNoteDocument> {
    const snapshot = await noteReference(this.teamId, attachment).get();
    if (!snapshot.exists) {
      throw new Error(`Wissensnotiz fehlt: ${attachment.noteId}`);
    }
    const data = snapshot.data() ?? {};
    return noteFromData(attachment, data);
  }
}

function noteReference(teamId: string, attachment: KnowledgeAttachment) {
  return getFirestore()
    .collection("teams")
    .doc(teamId)
    .collection("knowledgeBases")
    .doc(attachment.knowledgeBaseId)
    .collection("notes")
    .doc(attachment.noteId);
}

function noteFromData(
  attachment: KnowledgeAttachment,
  data: DocumentData,
): KnowledgeNoteDocument {
  return {
    knowledgeBaseId: attachment.knowledgeBaseId,
    noteId: attachment.noteId,
    title: stringValue(data.title, attachment.title),
    path: stringValue(data.path, attachment.path),
    type: noteTypeValue(data.type, attachment.type),
    content: stringValue(data.content, ""),
    outgoingLinks: stringListValue(data.outgoingLinks),
  };
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

function stringValue(value: unknown, fallback: string): string {
  return typeof value === "string" ? value : fallback;
}

function stringListValue(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((item): item is string => typeof item === "string");
}

function noteTypeValue(value: unknown, fallback: KnowledgeAttachment["type"]) {
  if (value === "atomic" || value === "moc" || value === "unknown") {
    return value;
  }
  return fallback;
}
