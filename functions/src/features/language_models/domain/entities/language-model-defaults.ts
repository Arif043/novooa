/**
 * Welche bereits verbundenen Sprachmodelle als Vorgabe gelten. `null` heißt
 * jeweils: nichts gewählt.
 *
 * - `blockModelId`: für Sprachmodell-Bausteine ("Standardmodell verwenden",
 *   `languageModelId === ""`); ohne Wahl bleibt der umgebungsvariablen-
 *   gesteuerte Standardmodell-Pfad (`ai-models.ts`) aktiv.
 * - `knowledgeAssistantModelId`: für den KI-Agenten der Wissensbasis in der
 *   lokalen Runtime; ohne Wahl gilt `blockModelId`. Die Agenten in der Cloud
 *   nutzen stattdessen das Modell aus Remote Config.
 */
export type LanguageModelDefaults = {
  blockModelId: string | null;
  knowledgeAssistantModelId: string | null;
};

export const emptyLanguageModelDefaults: LanguageModelDefaults = {
  blockModelId: null,
  knowledgeAssistantModelId: null,
};
