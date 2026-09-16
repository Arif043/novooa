import assert from "node:assert/strict";
import test from "node:test";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type ModelArtifactPublication} from "../../domain/repositories/model-artifact-publisher.js";
import {publishSystemModelCommand, type OnnxModelValidator, type SystemModelPublisher} from "./model-publish-command.js";
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

function dependencies(publisher: Publisher, validator: Validator) {
  return {
    publisher, onnxValidator: validator,
    manifestFromFile: async () => ({
      id: "model", title: "Modell", description: "Beschreibung", tags: ["bild"],
      artifact: {artifactId: "model", versionId: "1"}, contract: contract(),
    }),
    artifactFromFile: async (): Promise<ModelArtifactPublication> => ({
      reference: {
        artifactId: "model", versionId: "1", format: "onnx", contentType: "application/onnx",
        sizeBytes: 1, sha256: "0".repeat(64),
      },
      content: bytes(),
    }),
  };
}

function options(dryRun: boolean): ModelPublishOptions {
  return {
    projectId: "project", bucketName: "bucket", manifestPath: "model.json", artifactPath: "model.onnx",
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
