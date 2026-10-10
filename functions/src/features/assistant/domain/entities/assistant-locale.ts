/** Sprachen, in denen die App und damit der Agent antworten kann. */
export const assistantLocales = ["en", "de", "tr"] as const;

export type AssistantLocale = typeof assistantLocales[number];

export function assistantLocaleFrom(value: unknown): AssistantLocale | undefined {
  return assistantLocales.find((locale) => locale === value);
}
