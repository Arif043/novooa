import {type ModelTag} from "../domain/entities/model-tag.js";
import {ModelTagVocabulary} from "../domain/entities/model-tag-vocabulary.js";

/** Die Datei `models/tags.json`: `{"tags": [...]}`. */
export function modelTagVocabularyFromFileData(value: unknown): ModelTagVocabulary {
  const data = record(value, "Die Tag-Datei muss ein Objekt mit „tags“ sein.");
  if (!Array.isArray(data.tags)) throw new Error("Die Tag-Datei braucht eine Liste „tags“.");
  return new ModelTagVocabulary(data.tags.map((item) => {
    const tag = record(item, "Ein Eintrag der Tag-Datei ist ungültig.");
    return modelTagFromData(String(tag.key), tag);
  }));
}

/** Ein Dokument `modelTags/{key}` bzw. eine Zeile des Spiegels in der Runtime. */
export function modelTagFromData(key: string, data: Record<string, unknown>): ModelTag {
  const parent = data.parent;
  if (parent !== undefined && parent !== null && typeof parent !== "string") throw new Error(`Der Obertag von „${key}“ ist ungültig.`);
  const synonyms = data.synonyms === undefined || data.synonyms === null ? undefined : synonymsFrom(key, data.synonyms);
  return {
    key,
    ...(typeof parent === "string" ? {parent} : {}),
    labels: labelsFrom(key, data.labels),
    ...(synonyms === undefined ? {} : {synonyms}),
  };
}

/** Ohne `key`: Er ist die Dokument-ID bzw. der Primärschlüssel. */
export function modelTagData(tag: ModelTag) {
  return {
    parent: tag.parent ?? null,
    labels: {...tag.labels},
    synonyms: Object.fromEntries(Object.entries(tag.synonyms ?? {}).map(([locale, words]) => [locale, [...words]])),
  };
}

function labelsFrom(key: string, value: unknown): Record<string, string> {
  const data = record(value, `Die Bezeichnungen des Tags „${key}“ fehlen.`);
  if (!Object.values(data).every((label) => typeof label === "string")) {
    throw new Error(`Die Bezeichnungen des Tags „${key}“ sind ungültig.`);
  }
  return data as Record<string, string>;
}

function synonymsFrom(key: string, value: unknown): Record<string, readonly string[]> {
  const data = record(value, `Die Synonyme des Tags „${key}“ sind ungültig.`);
  const valid = Object.values(data).every((words) => Array.isArray(words) && words.every((word) => typeof word === "string"));
  if (!valid) throw new Error(`Die Synonyme des Tags „${key}“ sind ungültig.`);
  return data as Record<string, readonly string[]>;
}

function record(value: unknown, message: string): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) throw new Error(message);
  return value as Record<string, unknown>;
}
