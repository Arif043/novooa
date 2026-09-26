import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type ModelArtifactPublication} from "../../domain/repositories/model-artifact-publisher.js";
import {type PublishSystemModelRequest} from "../../domain/usecases/publish-system-model.js";
import {cloudModelContractCapabilityValidator, type ModelContractCapabilityValidator} from "../model-contract-capabilities.js";
import {modelArtifactFromFile} from "../model-artifact-from-file.js";
import {type OnnxModelValidationRequest} from "../python-onnx-model-validator.js";
import {type ModelPublishOptions} from "./model-publish-options.js";
import {systemModelEntry, systemModelManifestFromFile} from "./system-model-manifest.js";
import {type ModelArtifactDistribution} from "../model-artifact-distribution.js";

export type SystemModelPublisher = {
  execute(request: PublishSystemModelRequest): Promise<ModelCatalogEntry>;
};

export type SystemModelDistributionPublisher = {
  publish(modelId: string, distribution: ModelArtifactDistribution): Promise<void>;
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
  distributionPublisher?: SystemModelDistributionPublisher;
};

export type ModelPublishOutcome = {entry: ModelCatalogEntry; dryRun: boolean};

export async function publishSystemModelCommand(
  options: ModelPublishOptions,
  dependencies: ModelPublishCommandDependencies,
): Promise<ModelPublishOutcome> {
  const manifest = await (dependencies.manifestFromFile ?? systemModelManifestFromFile)(options.manifestPath);
  requireDistribution(manifest.distribution, dependencies.distributionPublisher);
  const artifact = await (dependencies.artifactFromFile ?? modelArtifactFromFile)({
    path: options.artifactPath, ...manifest.artifact,
  });
  const entry = systemModelEntry(manifest, artifact.reference);
  (dependencies.contractValidator ?? cloudModelContractCapabilityValidator()).validate(entry.contract);
  await dependencies.onnxValidator.validate({artifactPath: options.artifactPath, contract: entry.contract});
  return publishWhenRequested(options.dryRun, entry, artifact, dependencies.publisher, manifest.distribution,
    dependencies.distributionPublisher);
}

function publishWhenRequested(
  dryRun: boolean,
  entry: ModelCatalogEntry,
  artifact: ModelArtifactPublication,
  publisher: SystemModelPublisher,
  distribution: ModelArtifactDistribution | undefined,
  distributionPublisher: SystemModelDistributionPublisher | undefined,
): Promise<ModelPublishOutcome> {
  if (dryRun) return Promise.resolve({entry, dryRun});
  return publisher.execute({entry, artifact}).then(async (published) => {
    if (distribution !== undefined && distributionPublisher !== undefined) {
      await distributionPublisher.publish(published.id, distribution);
    }
    return {entry: published, dryRun};
  });
}

function requireDistribution(
  distribution: ModelArtifactDistribution | undefined,
  publisher: SystemModelDistributionPublisher | undefined,
): void {
  if (publisher !== undefined && distribution === undefined) {
    throw new Error("Der Betreiber-Publisher benötigt eine Modell-Distribution.");
  }
}
