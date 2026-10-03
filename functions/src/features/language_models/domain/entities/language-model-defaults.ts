/**
 * Welches bereits verbundene Sprachmodell als Vorgabe für Sprachmodell-
 * Bausteine gilt ("Standardmodell verwenden", `languageModelId === ""`). `null`
 * heißt: kein Vorgabemodell gewählt, der bisherige umgebungsvariablen-
 * gesteuerte Standardmodell-Pfad (`ai-models.ts`) bleibt aktiv. Das Modell des
 * KI-Agenten legt die Cloud fest, nicht der Nutzer.
 */
export type LanguageModelDefaults = {
  blockModelId: string | null;
};

export const emptyLanguageModelDefaults: LanguageModelDefaults = {
  blockModelId: null,
};
