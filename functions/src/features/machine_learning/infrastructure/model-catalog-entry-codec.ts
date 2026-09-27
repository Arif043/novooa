import {
  type ModelArtifactReference,
  validateModelArtifactReference,
} from "../domain/entities/model-artifact-reference.js";
import {
  type ModelCatalogEntry,
  type ModelScope,
  validateModelCatalogEntry,
} from "../domain/entities/model-catalog-entry.js";
import {modelContractFromUnknown} from "./model-contract-codec.js";

export type ModelCatalogEntryData = {
  id: string;
  title: string;
  description: string;
  tags: unknown;
  scope: unknown;
  teamId: unknown;
  runtime: unknown;
  artifactReference: unknown;
  contract: unknown;
};

export function modelCatalogEntryFromData(
  data: ModelCatalogEntryData,
): ModelCatalogEntry {
  const entry = {
    id: text(data.id, "Die Modell-ID fehlt."),
    title: text(data.title, "Der Modellname fehlt."),
    description: text(data.description, "Die Modellbeschreibung fehlt."),
    tags: tagsFrom(data.tags),
    scope: scopeFrom(data.scope, data.teamId),
    runtime: runtimeFrom(data.runtime),
    artifactReference: artifactFrom(data.artifactReference),
    contract: modelContractFromUnknown(data.contract),
  };
  validateModelCatalogEntry(entry);
  return entry;
}

export function modelCatalogEntryData(entry: ModelCatalogEntry) {
  return {
    id: entry.id,
    title: entry.title,
    description: entry.description,
    tags: [...entry.tags],
    scope: entry.scope.type,
    teamId: entry.scope.type === "team" ? entry.scope.teamId : null,
    runtime: entry.runtime,
    artifactReference: {...entry.artifactReference},
    contract: entry.contract,
  };
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
