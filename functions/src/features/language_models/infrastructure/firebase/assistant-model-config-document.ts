import {FieldValue} from "firebase-admin/firestore";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
import {assistantModelNameFrom} from "../../domain/entities/assistant-model-name.js";
import {type AssistantModelConfigDocument} from "../../domain/usecases/config-document-assistant-model.js";

function reference() {
  return getDatabase().collection("localRuntimeConfig").doc("assistant");
}

export async function readAssistantModelConfigDocument(): Promise<AssistantModelConfigDocument> {
  const snapshot = await reference().get();
  return snapshot.exists ? {assistantModel: snapshot.data()?.assistantModel} : undefined;
}

/** Der zuletzt veröffentlichte Name; `undefined`, wenn es das Dokument nicht gibt. */
export async function readPublishedAssistantModel(): Promise<string | null | undefined> {
  const document = await readAssistantModelConfigDocument();
  if (document === undefined) return undefined;
  return typeof document.assistantModel === "string" ? assistantModelNameFrom(document.assistantModel) : null;
}

/**
 * Schreibt den Namen und erhöht die Revision, damit die Runtimes auch beim
 * Wechsel auf `null` ein Ereignis sehen. Das Dokument enthält nur den Namen.
 */
export async function publishAssistantModelConfig(name: string | null): Promise<void> {
  await reference().set({
    assistantModel: name,
    revision: FieldValue.increment(1),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
}
