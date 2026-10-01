import {type ModelArtifactReference} from "../../domain/entities/model-artifact-reference.js";
import {type ModelArtifactPublication} from "../../domain/repositories/model-artifact-publisher.js";
import {type systemModelManifestFromUnknown} from "../cli/system-model-manifest.js";
import {type ModelArtifactDistribution} from "../model-artifact-distribution.js";
import {type StagedModelArtifact} from "./local-model-artifact-upload-store.js";
import {type ModelContractValidator} from "./python-model-contract-validator.js";

export interface ModelArtifactDownloader {
  download(reference: ModelArtifactReference, distribution: ModelArtifactDistribution): Promise<ModelArtifactPublication>;
}

export type SystemModelManifest = ReturnType<typeof systemModelManifestFromUnknown>;

/** Fachlich ungültige Eingaben (Manifest, Vertrag, Uploadgröße) — werden als 400 gemeldet. */
export class LocalModelCatalogRequestError extends Error {}

export function artifactReferenceFor(manifest: SystemModelManifest, staged: StagedModelArtifact) {
  return {
    artifactId: manifest.artifact.artifactId, versionId: manifest.artifact.versionId, format: "onnx" as const,
    contentType: "application/onnx", sizeBytes: staged.sizeBytes, sha256: staged.sha256,
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
