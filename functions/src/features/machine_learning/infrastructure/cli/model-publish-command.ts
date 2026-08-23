import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type ModelArtifactPublication} from "../../domain/repositories/model-artifact-publisher.js";
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

export async function publishSystemModelCommand(
  options: ModelPublishOptions,
  dependencies: ModelPublishCommandDependencies,
): Promise<ModelPublishOutcome> {
  const manifest = await (dependencies.manifestFromFile ?? systemModelManifestFromFile)(options.manifestPath);
  const artifact = await (dependencies.artifactFromFile ?? modelArtifactFromFile)({
    path: options.artifactPath, ...manifest.artifact,
  });
  const entry = systemModelEntry(manifest, artifact.reference);
  (dependencies.contractValidator ?? cloudModelContractCapabilityValidator()).validate(entry.contract);
  await dependencies.onnxValidator.validate({artifactPath: options.artifactPath, contract: entry.contract});
  return publishWhenRequested(options.dryRun, entry, artifact, dependencies.publisher);
}

function publishWhenRequested(
  dryRun: boolean,
  entry: ModelCatalogEntry,
  artifact: ModelArtifactPublication,
  publisher: SystemModelPublisher,
): Promise<ModelPublishOutcome> {
  if (dryRun) return Promise.resolve({entry, dryRun});
  return publisher.execute({entry, artifact}).then((published) => ({entry: published, dryRun}));
}
