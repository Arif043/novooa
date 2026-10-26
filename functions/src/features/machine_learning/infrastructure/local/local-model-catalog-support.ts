import {UnknownModelTagError} from "../../domain/entities/model-tag-vocabulary.js";
import {type ModelTagVocabularySource} from "../../domain/repositories/model-tag-vocabulary-source.js";
import {type systemModelManifestFromUnknown} from "../cli/system-model-manifest.js";
import {type StagedModelArtifact} from "./local-model-artifact-upload-store.js";
import {LocalModelCatalogRequestError} from "./local-model-catalog-errors.js";
import {type ModelContractValidator} from "./python-model-contract-validator.js";

export type SystemModelManifest = ReturnType<typeof systemModelManifestFromUnknown>;

export {LocalModelCatalogRequestError};

export function artifactReferenceFor(
  manifest: SystemModelManifest,
  staged: StagedModelArtifact,
  externalData: ReadonlyMap<string, StagedModelArtifact> = new Map(),
) {
  const weights = [...externalData].map(([name, file]) => ({name, sizeBytes: file.sizeBytes, sha256: file.sha256}));
  return {
    artifactId: manifest.artifact.artifactId, versionId: manifest.artifact.versionId, format: "onnx" as const,
    contentType: "application/onnx", sizeBytes: staged.sizeBytes, sha256: staged.sha256,
    ...(weights.length > 0 ? {externalData: weights} : {}),
  };
}

export async function validateContract(
  validator: ModelContractValidator, contract: Parameters<ModelContractValidator["validate"]>[0],
): Promise<void> {
  try {
    await validator.validate(contract);
  } catch (error) {
    throw new LocalModelCatalogRequestError(error instanceof Error ? error.message : "Das Manifest ist ungültig.");
  }
}

/** Eigene Modelle nutzen nur Tags des Vokabulars; ein unbekannter Tag ist ein fachlicher Fehler (400). */
export async function requireKnownTags(source: ModelTagVocabularySource, tags: readonly string[]): Promise<void> {
  try {
    (await source.load()).requireKnown(tags);
  } catch (error) {
    if (error instanceof UnknownModelTagError) throw new LocalModelCatalogRequestError(error.message);
    throw error;
  }
}

export function contentLength(header: string | undefined): number | null {
  if (header === undefined) return null;
  const length = Number(header);
  if (!Number.isSafeInteger(length) || length < 0) throw new LocalModelCatalogRequestError("Die Uploadgröße ist ungültig.");
  return length;
}

export function isRequestError(error: unknown): error is Error {
  return error instanceof LocalModelCatalogRequestError ||
    (error instanceof Error && error.message === "Diese lokale Modellversion ist bereits installiert.");
}
