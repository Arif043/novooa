import {type DocumentData} from "firebase-admin/firestore";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
import {
  type KnowledgeBaseAssistantNote,
  type KnowledgeBaseAssistantNoteStore,
} from "../../domain/repositories/knowledge-base-assistant-note-store.js";

export class FirestoreKnowledgeBaseAssistantNoteStore
  implements KnowledgeBaseAssistantNoteStore {
  async listNotes(teamId: string): Promise<KnowledgeBaseAssistantNote[]> {
    const snapshot = await notesReference(teamId).limit(50).get();
    return snapshot.docs.map((document) => noteFromData(document.id, document.data()));
  }

  async findNote(
    teamId: string,
    noteId: string,
  ): Promise<KnowledgeBaseAssistantNote | null> {
    const snapshot = await notesReference(teamId).doc(noteId).get();
    if (!snapshot.exists) return null;
    return noteFromData(snapshot.id, snapshot.data() ?? {});
  }
}

function notesReference(teamId: string) {
  return getDatabase()
    .collection("teams")
    .doc(teamId)
    .collection("knowledgeBases")
    .doc("default")
    .collection("notes");
}

function noteFromData(
  id: string,
  data: DocumentData,
): KnowledgeBaseAssistantNote {
  return {
    id,
    title: textValue(data.title, "Unbenannte Notiz"),
    path: textValue(data.path, `${id}.md`),
    content: textValue(data.content, ""),
  };
}

function textValue(value: unknown, fallback: string): string {
  return typeof value === "string" ? value : fallback;
}
