/**
 * Welches bereits verbundene Sprachmodell als Vorgabe gilt — für
 * Sprachmodell-Bausteine ("Standardmodell verwenden",
 * `languageModelId === ""`) und für den KI-Agenten. `null` heißt: kein
 * Vorgabemodell gewählt, der bisherige umgebungsvariablen-gesteuerte
 * Standardmodell-Pfad (`ai-models.ts`) bleibt aktiv.
 */
export type LanguageModelDefaults = {
  blockModelId: string | null;
  assistantModelId: string | null;
};

export const emptyLanguageModelDefaults: LanguageModelDefaults = {
  blockModelId: null,
  assistantModelId: null,
};
