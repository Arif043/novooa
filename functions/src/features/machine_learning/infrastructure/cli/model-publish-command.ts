import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type ModelContractCheck} from "../../domain/repositories/system-model-source.js";
import {type PublishSystemModelRequest} from "../../domain/usecases/publish-system-model.js";
import {modelArtifactFromFile} from "../model-artifact-from-file.js";
import {type OnnxModelValidationRequest} from "../python-onnx-model-validator.js";
import {type ModelPublishOptions} from "./model-publish-options.js";
import {systemModelEntry, systemModelManifestFromFile} from "./system-model-manifest.js";

export type SystemModelPublisher = {
  check(request: PublishSystemModelRequest): Promise<void>;
  execute(request: PublishSystemModelRequest): Promise<ModelCatalogEntry>;
};

export type OnnxModelValidator = {
  validate(request: OnnxModelValidationRequest): Promise<void>;
};

export type ModelPublishCommandDependencies = {
  publisher: SystemModelPublisher;
  /** Kette, Parameter und Setting-Bindungen, geprüft vom Transformationskatalog des ML-Dienstes. */
  contractValidator: ModelContractCheck;
  onnxValidator: OnnxModelValidator;
  artifactFromFile?: typeof modelArtifactFromFile;
  manifestFromFile?: typeof systemModelManifestFromFile;
};

export type ModelPublishOutcome = {entry: ModelCatalogEntry; dryRun: boolean};

/**
 * Prüft ein Systemmodell (Vertrag, ONNX-Datei samt Gewichten, Version im Katalog) und veröffentlicht
 * Dateien und Katalogeintrag. Der Vertrag wird vor dem Hashen geprüft, weil Gewichte Gigabytes groß sein können.
 */
export async function publishSystemModelCommand(
  options: ModelPublishOptions,
  dependencies: ModelPublishCommandDependencies,
): Promise<ModelPublishOutcome> {
  const manifest = await (dependencies.manifestFromFile ?? systemModelManifestFromFile)(options.manifestPath);
  await dependencies.contractValidator.validate(manifest.contract);
  await dependencies.onnxValidator.validate({artifactPath: options.artifactPath, contract: manifest.contract});
  const artifact = await (dependencies.artifactFromFile ?? modelArtifactFromFile)({
    path: options.artifactPath, ...manifest.artifact,
    externalDataPaths: options.externalDataPaths, resources: options.resources,
  });
  const request = {entry: systemModelEntry(manifest, artifact.reference), artifact, replaceVersion: options.replaceVersion};
  if (options.dryRun) {
    await dependencies.publisher.check(request);
    return {entry: request.entry, dryRun: true};
  }
  return {entry: await dependencies.publisher.execute(request), dryRun: false};
}
