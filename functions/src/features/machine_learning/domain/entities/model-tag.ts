/**
 * Ein fachliches Thema aus dem kontrollierten Tag-Vokabular, etwa „Tiere“ oder „Rechnungen“.
 * Einträge verweisen nur über den Schlüssel darauf; Bezeichnungen und Synonyme stehen einmal hier,
 * nicht in jedem Manifest.
 */
export type ModelTag = {
  key: string;
  /** Obertag; ein Modell mit `pets` wird auch unter `animals` gefunden. */
  parent?: string;
  /** Sprachcode (BCP 47) → Bezeichnung; `en` ist Pflicht und Rückfall. */
  labels: Readonly<Record<string, string>>;
  /** Weitere Suchbegriffe je Sprache, z. B. „Hund“ für `pets`. */
  synonyms?: Readonly<Record<string, readonly string[]>>;
};

export const fallbackTagLocale = "en";

const keyPattern = /^[a-z0-9]+(-[a-z0-9]+)*$/;
const localePattern = /^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$/;

/** Schlüssel sind ASCII in Kebab-Schreibweise, damit sie in jeder Sprache gleich bleiben. */
export function isModelTagKey(value: string): boolean {
  return keyPattern.test(value);
}

export function validateModelTag(tag: ModelTag): void {
  if (!isModelTagKey(tag.key)) throw new Error(`Der Tag-Schlüssel „${tag.key}“ ist ungültig (erlaubt: a-z, 0-9, Bindestrich).`);
  if (tag.parent !== undefined && !isModelTagKey(tag.parent)) throw new Error(`Der Obertag von „${tag.key}“ ist ungültig.`);
  if (tag.parent === tag.key) throw new Error(`Der Tag „${tag.key}“ kann nicht sein eigener Obertag sein.`);
  validateLabels(tag);
  for (const [locale, synonyms] of Object.entries(tag.synonyms ?? {})) {
    requireLocale(tag.key, locale);
    if (synonyms.some((synonym) => synonym.trim().length === 0)) {
      throw new Error(`Der Tag „${tag.key}“ hat ein leeres Synonym (${locale}).`);
    }
  }
}

function validateLabels(tag: ModelTag): void {
  if ((tag.labels[fallbackTagLocale] ?? "").trim().length === 0) {
    throw new Error(`Dem Tag „${tag.key}“ fehlt die englische Bezeichnung.`);
  }
  for (const [locale, label] of Object.entries(tag.labels)) {
    requireLocale(tag.key, locale);
    if (label.trim().length === 0) throw new Error(`Die Bezeichnung des Tags „${tag.key}“ (${locale}) ist leer.`);
  }
}

function requireLocale(key: string, locale: string): void {
  if (!localePattern.test(locale)) throw new Error(`Der Sprachcode „${locale}“ des Tags „${key}“ ist ungültig.`);
}
