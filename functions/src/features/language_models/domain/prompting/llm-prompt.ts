import {type PromptSection} from "./prompt-section.js";

/** Eine frühere Nachricht eines Gesprächs; `model` ist die Antwort des Modells. */
export type LlmMessage = {
  readonly role: "user" | "model";
  readonly text: string;
};

/**
 * Ein fertig aufgebauter Prompt, unabhängig vom Format: Abschnitte für System- und Nutzerteil,
 * Bilder als eigene Teile und der Gesprächsverlauf. Den Text erzeugt erst ein `PromptRenderer`.
 */
export type LlmPrompt = {
  readonly systemSections: readonly PromptSection[];
  readonly userSections: readonly PromptSection[];
  /** Data- oder Datei-URLs von Bildern; sie gehen als Medienteile mit, nicht als Text. */
  readonly mediaUrls: readonly string[];
  readonly history: readonly LlmMessage[];
};
