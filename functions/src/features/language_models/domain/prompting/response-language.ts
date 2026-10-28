/** Sprachen, die eine Antwort fest vorgeben kann — dieselben wie in der App. */
export type ResponseLanguage = "en" | "de" | "tr";

/**
 * Wie das Modell die Antwortsprache wählt. Die festen Prompt-Texte sind englisch; ohne diese
 * Vorgabe antworten Modelle oft englisch, obwohl die Aufgabe deutsch gestellt ist.
 */
export type ResponseLanguagePolicy =
  | {readonly kind: "sameAsTask"}
  | {readonly kind: "fixed"; readonly language: ResponseLanguage};

export const sameAsTask: ResponseLanguagePolicy = {kind: "sameAsTask"};

const languageNames: Record<ResponseLanguage, string> = {en: "English", de: "German", tr: "Turkish"};

export function responseLanguageInstruction(policy: ResponseLanguagePolicy): string {
  if (policy.kind === "fixed") return `Respond in ${languageNames[policy.language]}.`;
  return [
    "Respond in the language the task is written in.",
    "Keep names, quotes and data values exactly as they are.",
  ].join(" ");
}
