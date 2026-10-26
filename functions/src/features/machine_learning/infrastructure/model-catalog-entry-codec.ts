import {
  type ModelArtifactReference,
  validateModelArtifactReference,
} from "../domain/entities/model-artifact-reference.js";
import {
  type ModelCatalogEntry,
  type ModelOrigin,
  type ModelScope,
  type ModelTranslations,
  validateModelCatalogEntry,
} from "../domain/entities/model-catalog-entry.js";
import {isModelTask, type ModelTask} from "../domain/entities/model-task.js";
import {modelContractFromUnknown} from "./model-contract-codec.js";

export type ModelCatalogEntryData = {
  id: string;
  title: string;
  description: string;
  translations?: unknown;
  task?: unknown;
  languages?: unknown;
  tags: unknown;
  scope: unknown;
  teamId: unknown;
  runtime: unknown;
  artifactReference: unknown;
  contract: unknown;
  origin?: unknown;
};

export function modelCatalogEntryFromData(
  data: ModelCatalogEntryData,
): ModelCatalogEntry {
  const translations = modelTranslationsFromUnknown(data.translations);
  const entry = {
    id: text(data.id, "Die Modell-ID fehlt."),
    title: text(data.title, "Der Modellname fehlt."),
    description: text(data.description, "Die Modellbeschreibung fehlt."),
    ...(translations === undefined ? {} : {translations}),
    task: taskFrom(data.task),
    languages: languagesFrom(data.languages),
    tags: tagsFrom(data.tags),
    scope: scopeFrom(data.scope, data.teamId),
    runtime: runtimeFrom(data.runtime),
    artifactReference: artifactFrom(data.artifactReference),
    contract: modelContractFromUnknown(data.contract),
    ...originFrom(data.origin),
  };
  validateModelCatalogEntry(entry);
  return entry;
}

export function modelCatalogEntryData(entry: ModelCatalogEntry) {
  return {
    id: entry.id,
    title: entry.title,
    description: entry.description,
    translations: entry.translations ?? {},
    task: entry.task,
    languages: [...entry.languages],
    tags: [...entry.tags],
    scope: entry.scope.type,
    teamId: entry.scope.type === "team" ? entry.scope.teamId : null,
    runtime: entry.runtime,
    artifactReference: {...entry.artifactReference},
    contract: entry.contract,
    ...(entry.origin === undefined ? {} : {origin: entry.origin}),
  };
}

/**
 * Gespeicherte Einträge ohne Aufgabe, mit einer entfernten oder einer noch unbekannten Aufgabe (neuerer
 * Katalog) gelten als „Sonstige“: Ein einzelner Eintrag darf das Lesen des Katalogs nicht verhindern.
 * Veröffentlichung und Import prüfen die Aufgabe streng.
 */
function taskFrom(value: unknown): ModelTask {
  return isModelTask(value) ? value : "other";
}

function languagesFrom(value: unknown): readonly string[] {
  if (value === undefined || value === null) return [];
  if (Array.isArray(value) && value.every((language) => typeof language === "string")) return value;
  throw new Error("Die Modellsprachen sind ungültig.");
}

function originFrom(value: unknown): {origin?: ModelOrigin} {
  if (value === undefined || value === null) return {};
  if (value === "catalog" || value === "import") return {origin: value};
  throw new Error("Die Herkunft des Modells ist ungültig.");
}

/** `undefined`/`null` (ältere Einträge ohne Übersetzungen) ergibt keine Übersetzungen. */
export function modelTranslationsFromUnknown(value: unknown): ModelTranslations | undefined {
  if (value === undefined || value === null) return undefined;
  const data = record(value, "Die Modellübersetzungen sind ungültig.");
  return Object.fromEntries(Object.entries(data).map(([locale, item]) => {
    const translation = record(item, `Die Modellübersetzung (${locale}) ist ungültig.`);
    return [locale, {
      title: text(translation.title, `Der übersetzte Modellname (${locale}) fehlt.`),
      description: text(translation.description, `Die übersetzte Modellbeschreibung (${locale}) fehlt.`),
      ...(translation.tags === undefined ? {} : {tags: tagsFrom(translation.tags)}),
    }];
  }));
}

function tagsFrom(value: unknown): readonly string[] {
  if (!Array.isArray(value) || !value.every((tag) => typeof tag === "string")) {
    throw new Error("Die Modell-Tags sind ungültig.");
  }
  return value;
}

function scopeFrom(scope: unknown, teamId: unknown): ModelScope {
  if (scope === "system") return {type: "system"};
  if (scope === "team" && typeof teamId === "string") return {type: "team", teamId};
  throw new Error("Der Modellbereich ist ungültig.");
}

function runtimeFrom(value: unknown): "onnx" {
  if (value === "onnx") return value;
  throw new Error("Die Modell-Runtime ist ungültig.");
}

function artifactFrom(value: unknown): ModelArtifactReference {
  const data = record(value, "Die Modell-Artefakt-Referenz ist ungültig.");
  const reference = {
    artifactId: text(data.artifactId, "Die Modell-Artefakt-ID fehlt."),
    versionId: text(data.versionId, "Die Modell-Artefakt-Version fehlt."),
    format: formatFrom(data.format),
    contentType: text(data.contentType, "Der Modell-Content-Type fehlt."),
    sizeBytes: numberFrom(data.sizeBytes),
    sha256: text(data.sha256, "Die Modell-Prüfsumme fehlt."),
    resources: resourcesFrom(data.resources),
    ...(data.externalData === undefined ? {} : {externalData: externalDataFrom(data.externalData)}),
  };
  validateModelArtifactReference(reference);
  return reference;
}

function resourcesFrom(value: unknown): readonly {name: string; contentType: string; sizeBytes: number; sha256: string}[] {
  if (value === undefined) return [];
  if (!Array.isArray(value)) throw new Error("Die Modellressourcen sind ungültig.");
  return value.map((item) => {
    const data = record(item, "Die Modellressource ist ungültig.");
    return {name: text(data.name, "Der Name einer Modellressource fehlt."), contentType: text(data.contentType, "Der Content-Type einer Modellressource fehlt."), sizeBytes: numberFrom(data.sizeBytes), sha256: text(data.sha256, "Die Prüfsumme einer Modellressource fehlt.")};
  });
}

function externalDataFrom(value: unknown): readonly {name: string; sizeBytes: number; sha256: string}[] {
  if (!Array.isArray(value)) throw new Error("Die Gewichtsdateien des Modells sind ungültig.");
  return value.map((item) => {
    const data = record(item, "Eine Gewichtsdatei des Modells ist ungültig.");
    return {name: text(data.name, "Der Name einer Gewichtsdatei fehlt."), sizeBytes: numberFrom(data.sizeBytes), sha256: text(data.sha256, "Die Prüfsumme einer Gewichtsdatei fehlt.")};
  });
}

function formatFrom(value: unknown): "onnx" {
  if (value === "onnx") return value;
  throw new Error("Das Modell-Artefaktformat ist ungültig.");
}

function numberFrom(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  throw new Error("Die Modell-Artefaktgröße ist ungültig.");
}

function text(value: unknown, message: string): string {
  if (typeof value !== "string" || value.trim().length === 0) throw new Error(message);
  return value;
}

function record(value: unknown, message: string): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) throw new Error(message);
  return value as Record<string, unknown>;
}
