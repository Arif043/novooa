import {readFile} from "node:fs/promises";
import {type ModelCatalogEntry, type ModelTranslations, validateModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type ModelArtifactReference} from "../../domain/entities/model-artifact-reference.js";
import {type ModelContract} from "../../domain/entities/model-contract.js";
import {isModelTask, modelTasks, type ModelTask} from "../../domain/entities/model-task.js";
import {modelContractFromUnknown} from "../model-contract-codec.js";
import {modelTranslationsFromUnknown} from "../model-catalog-entry-codec.js";

export type SystemModelManifest = {
  id: string;
  title: string;
  description: string;
  translations?: ModelTranslations;
  task: ModelTask;
  languages: readonly string[];
  tags: readonly string[];
  artifact: {artifactId: string; versionId: string};
  contract: ModelContract;
};

export async function systemModelManifestFromFile(path: string): Promise<SystemModelManifest> {
  const content = await readFile(path, "utf8");
  return systemModelManifestFromUnknown(JSON.parse(content));
}

export function systemModelManifestFromUnknown(value: unknown): SystemModelManifest {
  const data = record(value, "Die Modellmanifest-Datei ist ungültig.");
  const translations = modelTranslationsFromUnknown(data.translations);
  const manifest = {
    id: text(data.id, "Die Modell-ID fehlt."),
    title: text(data.title, "Der Modellname fehlt."),
    description: text(data.description, "Die Modellbeschreibung fehlt."),
    ...(translations === undefined ? {} : {translations}),
    task: task(data.task), languages: languages(data.languages),
    tags: tags(data.tags), artifact: artifact(data.artifact),
    contract: modelContractFromUnknown(data.contract),
  };
  return manifest;
}

export function systemModelEntry(
  manifest: SystemModelManifest,
  artifactReference: ModelArtifactReference,
): ModelCatalogEntry {
  const entry: ModelCatalogEntry = {
    id: manifest.id, title: manifest.title, description: manifest.description,
    ...(manifest.translations === undefined ? {} : {translations: manifest.translations}),
    task: manifest.task, languages: manifest.languages, tags: manifest.tags,
    scope: {type: "system"}, runtime: "onnx", artifactReference, contract: manifest.contract,
  };
  validateModelCatalogEntry(entry);
  return entry;
}

function artifact(value: unknown): {artifactId: string; versionId: string} {
  const data = record(value, "Die Artefaktdefinition ist ungültig.");
  return {
    artifactId: text(data.artifactId, "Die Modell-Artefakt-ID fehlt."),
    versionId: text(data.versionId, "Die Modell-Artefakt-Version fehlt."),
  };
}

/** Pflicht im Manifest: Ohne Aufgabe ließe sich das Modell in der Suche nicht einordnen. */
function task(value: unknown): ModelTask {
  if (isModelTask(value)) return value;
  throw new Error(`Die Modellaufgabe („task“) fehlt oder ist unbekannt. Erlaubt sind: ${modelTasks.join(", ")}.`);
}

function languages(value: unknown): readonly string[] {
  if (value === undefined) return [];
  if (!Array.isArray(value) || !value.every((language) => typeof language === "string")) {
    throw new Error("Die Modellsprachen sind ungültig.");
  }
  return value;
}

function tags(value: unknown): readonly string[] {
  if (!Array.isArray(value) || !value.every((tag) => typeof tag === "string")) {
    throw new Error("Die Modell-Tags sind ungültig.");
  }
  return value;
}

function record(value: unknown, message: string): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) throw new Error(message);
  return value as Record<string, unknown>;
}

function text(value: unknown, message: string): string {
  if (typeof value !== "string" || value.trim().length === 0) throw new Error(message);
  return value;
}
