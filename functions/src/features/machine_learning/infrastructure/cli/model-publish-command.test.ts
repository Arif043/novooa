import assert from "node:assert/strict";
import test from "node:test";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type ModelArtifactPublication} from "../../domain/repositories/model-artifact-publisher.js";
import {
  publishSystemModelCommand,
  type OnnxModelValidator,
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

test("passes weight files and resources of the options to the artifact", async () => {
  const requested: Parameters<typeof dependencies>[0][] = [];
  await publishSystemModelCommand({...options(false), externalDataPaths: ["dir/weights.bin"], resources: [{name: "labels", path: "labels.json"}]}, {
    ...dependencies(new Publisher(), new Validator()),
    artifactFromFile: async (file) => {
      requested.push(file as never);
      return dependencies(new Publisher(), new Validator()).artifactFromFile();
    },
  });

  assert.deepEqual(requested, [{
    path: "model.onnx", artifactId: "model", versionId: "1",
    externalDataPaths: ["dir/weights.bin"], resources: [{name: "labels", path: "labels.json"}],
  }]);
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
    id: "model", title: "Modell", description: "Beschreibung", task: "image-classification" as const, languages: [], tags: ["bild"],
    artifact: {artifactId: "model", versionId: "1"}, contract: contract(),
  };
}

function options(dryRun: boolean): ModelPublishOptions {
  return {
    projectId: "project", manifestPath: "model.json", artifactPath: "model.onnx",
    externalDataPaths: [], resources: [], pythonExecutable: "python3", dryRun,
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
