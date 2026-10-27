import {isQueryableFieldName} from "../entities/document-filter.js";

export type RenamedField = {from: string; to: string};

export type NormalizedFieldNames = {
  /** Feldname je Eingabespalte, in derselben Reihenfolge. */
  fields: string[];
  renamed: RenamedField[];
};

const maximumLength = 64;
const transliterations: Record<string, string> = {
  "ä": "ae", "ö": "oe", "ü": "ue", "Ä": "Ae", "Ö": "Oe", "Ü": "Ue", "ß": "ss",
};

/**
 * Macht Spaltennamen zu Feldnamen, nach denen gefiltert und sortiert werden kann:
 * Umlaute umschreiben, Akzente entfernen, alles andere zu `_`, eindeutig mit `_2`, `_3` …
 */
export function normalizeFieldNames(names: readonly string[]): NormalizedFieldNames {
  const used = new Set<string>();
  const fields = names.map((name) => unique(normalizedFieldName(name), used));
  const renamed = names.flatMap((name, index) => name === fields[index] ? [] : [{from: name, to: fields[index]}]);
  return {fields, renamed};
}

export function normalizedFieldName(name: string): string {
  if (isQueryableFieldName(name)) return name;
  const ascii = [...name.trim()].map((character) => transliterations[character] ?? character).join("")
    .normalize("NFKD").replace(/\p{Diacritic}/gu, "");
  const cleaned = ascii.replace(/[^A-Za-z0-9_]+/g, "_").replace(/_+/g, "_").replace(/^_+|_+$/g, "");
  if (cleaned.length === 0) return "feld";
  const prefixed = /^[0-9]/.test(cleaned) ? `feld_${cleaned}` : cleaned;
  return prefixed.slice(0, maximumLength);
}

function unique(field: string, used: Set<string>): string {
  let candidate = field;
  for (let suffix = 2; used.has(candidate); suffix += 1) {
    const ending = `_${suffix}`;
    candidate = field.slice(0, maximumLength - ending.length) + ending;
  }
  used.add(candidate);
  return candidate;
}
