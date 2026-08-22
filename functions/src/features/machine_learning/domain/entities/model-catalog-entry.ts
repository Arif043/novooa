import {
  type ModelArtifactReference,
  validateModelArtifactReference,
} from "./model-artifact-reference.js";
import {type ModelContract, validateModelContract} from "./model-contract.js";

export type ModelScope =
  | {type: "system"}
  | {type: "team"; teamId: string};

export type ModelCatalogEntry = {
  id: string;
  title: string;
  description: string;
  tags: readonly string[];
  scope: ModelScope;
  runtime: "onnx";
  artifactReference: ModelArtifactReference;
  contract: ModelContract;
};

export function validateModelCatalogEntry(entry: ModelCatalogEntry): void {
  required(entry.id, "Die Modell-ID fehlt.");
  required(entry.title, "Der Modellname fehlt.");
  required(entry.description, "Die Modellbeschreibung fehlt.");
  validTags(entry.tags);
  validScope(entry.scope);
  validateModelArtifactReference(entry.artifactReference);
  validateModelContract(entry.contract);
}

function validTags(tags: readonly string[]): void {
  const normalized = tags.map((tag) => tag.trim().toLowerCase());
  if (normalized.some((tag) => tag.length === 0)) throw new Error("Modell-Tags dürfen nicht leer sein.");
  if (new Set(normalized).size !== normalized.length) throw new Error("Modell-Tags müssen eindeutig sein.");
}

function validScope(scope: ModelScope): void {
  if (scope.type === "system") return;
  required(scope.teamId, "Der Team-Bereich benötigt eine Team-ID.");
}

function required(value: string, message: string): void {
  if (value.trim().length === 0) throw new Error(message);
}
