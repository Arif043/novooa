import assert from "node:assert/strict";
import test from "node:test";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type ModelArtifactPublication} from "../../domain/repositories/model-artifact-publisher.js";
import {
  publishSystemModelCommand,
  type OnnxModelValidator,
  type SystemModelDistributionPublisher,
  type SystemModelPublisher,
} from "./model-publish-command.js";
import {type ModelPublishOptions} from "./model-publish-options.js";

test("validates a model without persisting during a dry run", async () => {
  const publisher = new Publisher();
  const validator = new Validator();
  const outcome = await publishSystemModelCommand(options(true), dependencies(publisher, validator));

  assert.equal(outcome.dryRun, true);
  assert.equal(validator.calls, 1);
  assert.equal(publisher.calls, 0);
});

test("publishes a verified system model", async () => {
  const publisher = new Publisher();
  const outcome = await publishSystemModelCommand(options(false), dependencies(publisher, new Validator()));

  assert.equal(outcome.entry.id, "model");
  assert.equal(publisher.calls, 1);
});

test("persists a manifest distribution separately from the catalog entry", async () => {
  const publisher = new Publisher();
  const distributions = new DistributionPublisher();
  await publishSystemModelCommand(options(false), {
    ...dependencies(publisher, new Validator()),
    distributionPublisher: distributions,
    manifestFromFile: async () => ({
      ...manifest(), distribution: distribution(),
    }),
  });

  assert.deepEqual(distributions.items, [{modelId: "model", distribution: distribution()}]);
});

class Publisher implements SystemModelPublisher {
  calls = 0;

  async execute(request: {entry: ModelCatalogEntry}): Promise<ModelCatalogEntry> {
    this.calls += 1;
    return request.entry;
  }
}

class Validator implements OnnxModelValidator {
  calls = 0;

  async validate(): Promise<void> {
    this.calls += 1;
  }
}

class DistributionPublisher implements SystemModelDistributionPublisher {
  items: {modelId: string; distribution: ReturnType<typeof distribution>}[] = [];

  async publish(modelId: string, value: ReturnType<typeof distribution>): Promise<void> {
    this.items.push({modelId, distribution: value});
  }
}

function dependencies(publisher: Publisher, validator: Validator) {
  return {
    publisher, onnxValidator: validator,
    manifestFromFile: async () => manifest(),
    artifactFromFile: async (): Promise<ModelArtifactPublication> => ({
      reference: {
        artifactId: "model", versionId: "1", format: "onnx", contentType: "application/onnx",
        sizeBytes: 1, sha256: "0".repeat(64),
      },
      content: bytes(),
    }),
  };
}

function manifest() {
  return {
    id: "model", title: "Modell", description: "Beschreibung", tags: ["bild"],
    artifact: {artifactId: "model", versionId: "1"}, contract: contract(),
  };
}

function distribution() {
  return {
    type: "huggingFace" as const,
    repository: "novooa/model",
    revision: "a".repeat(40),
    path: "model.onnx",
  };
}

function options(dryRun: boolean): ModelPublishOptions {
  return {
    projectId: "project", manifestPath: "model.json", artifactPath: "model.onnx",
    pythonExecutable: "python3", dryRun,
  };
}

function contract() {
  return {
    inputs: [{name: "input", source: "tensor" as const, dataType: "uint8" as const, shape: [1], transformations: []}],
    outputs: [{name: "output", semantic: "test", dataType: "uint8" as const, shape: [1], transformations: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"}}],
  };
}

async function* bytes(): AsyncGenerator<Uint8Array> {
  yield Uint8Array.from([1]);
}
