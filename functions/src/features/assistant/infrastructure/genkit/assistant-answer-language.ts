import {type AssistantLocale} from "../../domain/entities/assistant-locale.js";

const languageNames: Record<AssistantLocale, string> = {en: "English", de: "Deutsch", tr: "Türkçe"};

/**
 * Hängt die Antwortsprache an den Nutzerprompt. Ohne Angabe (ältere Clients)
 * bleibt der Prompt unverändert und der Agent antwortet wie bisher auf Deutsch.
 */
export function promptWithAnswerLanguage(prompt: string, locale: AssistantLocale | undefined): string {
  if (!locale) return prompt;
  return `${prompt}\n\nAntwortsprache: ${languageNames[locale]}. Formuliere answer und alle label-Texte der Commands in dieser Sprache.`;
}
