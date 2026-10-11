import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type PublishSystemModelRequest} from "../../domain/usecases/publish-system-model.js";
import {cloudModelContractCapabilityValidator, type ModelContractCapabilityValidator} from "../model-contract-capabilities.js";
import {modelArtifactFromFile} from "../model-artifact-from-file.js";
import {type OnnxModelValidationRequest} from "../python-onnx-model-validator.js";
import {type ModelPublishOptions} from "./model-publish-options.js";
import {systemModelEntry, systemModelManifestFromFile} from "./system-model-manifest.js";

export type SystemModelPublisher = {
  execute(request: PublishSystemModelRequest): Promise<ModelCatalogEntry>;
};

export type OnnxModelValidator = {
  validate(request: OnnxModelValidationRequest): Promise<void>;
};

export type ModelPublishCommandDependencies = {
  publisher: SystemModelPublisher;
  contractValidator?: ModelContractCapabilityValidator;
  onnxValidator: OnnxModelValidator;
  artifactFromFile?: typeof modelArtifactFromFile;
  manifestFromFile?: typeof systemModelManifestFromFile;
};

export type ModelPublishOutcome = {entry: ModelCatalogEntry; dryRun: boolean};

/** Prüft ein Systemmodell (Vertrag, ONNX-Datei samt Gewichten) und veröffentlicht Dateien und Katalogeintrag. */
export async function publishSystemModelCommand(
  options: ModelPublishOptions,
  dependencies: ModelPublishCommandDependencies,
): Promise<ModelPublishOutcome> {
  const manifest = await (dependencies.manifestFromFile ?? systemModelManifestFromFile)(options.manifestPath);
  const artifact = await (dependencies.artifactFromFile ?? modelArtifactFromFile)({
    path: options.artifactPath, ...manifest.artifact,
    externalDataPaths: options.externalDataPaths, resources: options.resources,
  });
  const entry = systemModelEntry(manifest, artifact.reference);
  (dependencies.contractValidator ?? cloudModelContractCapabilityValidator()).validate(entry.contract);
  await dependencies.onnxValidator.validate({artifactPath: options.artifactPath, contract: entry.contract});
  if (options.dryRun) return {entry, dryRun: true};
  return {entry: await dependencies.publisher.execute({entry, artifact}), dryRun: false};
}
