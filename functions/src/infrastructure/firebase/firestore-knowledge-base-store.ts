import {type DocumentData} from "firebase-admin/firestore";
import {type KnowledgeAttachment} from "../../domain/entities/attachments.js";
import {getDatabase} from "./firestore-db.js";
import {
  type KnowledgeBaseStore,
  type KnowledgeNoteDocument,
} from "../../domain/repositories/knowledge-base-store.js";

export class FirestoreKnowledgeBaseStore implements KnowledgeBaseStore {
  async loadNote(
    teamId: string,
    attachment: KnowledgeAttachment,
  ): Promise<KnowledgeNoteDocument> {
    const snapshot = await notesReference(teamId, attachment).get();
    if (!snapshot.exists) {
      throw new Error(`Wissensnotiz fehlt: ${attachment.noteId}`);
    }
    return noteFromData(attachment, snapshot.data() ?? {});
  }
}

function notesReference(teamId: string, attachment: KnowledgeAttachment) {
  return getDatabase()
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
