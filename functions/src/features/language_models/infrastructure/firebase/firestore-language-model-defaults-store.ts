import {
  emptyLanguageModelDefaults,
  type LanguageModelDefaults,
} from "../../domain/entities/language-model-defaults.js";
import {type LanguageModelDefaultsStore} from "../../domain/repositories/language-model-defaults-store.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";

/**
 * Liegt direkt auf dem `teams/{teamId}`-Dokument, nicht in einer eigenen
 * Collection: Anders als Modelle/Verbindungen enthält die Vorgabe keine
 * Geheimnisse, ein eigener Schreib-Callable ist deshalb nicht nötig.
 */
export class FirestoreLanguageModelDefaultsStore
  implements LanguageModelDefaultsStore {
  async loadDefaults(teamId: string): Promise<LanguageModelDefaults> {
    const snapshot = await teamDoc(teamId).get();
    const value = snapshot.data()?.languageModelDefaults;
    if (!value || typeof value !== "object") return emptyLanguageModelDefaults;
    return {
      blockModelId: stringOrNull(value.blockModelId),
      assistantModelId: stringOrNull(value.assistantModelId),
    };
  }

  async saveDefaults(teamId: string, defaults: LanguageModelDefaults): Promise<void> {
    await teamDoc(teamId).set({languageModelDefaults: defaults}, {merge: true});
  }
}

function teamDoc(teamId: string) {
  return getDatabase().collection("teams").doc(teamId);
}

function stringOrNull(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}
