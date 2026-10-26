import assert from "node:assert/strict";
import test from "node:test";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type ModelContractCheck} from "../../domain/repositories/system-model-source.js";
import {type ModelArtifactPublication} from "../../domain/repositories/model-artifact-publisher.js";
import {type PublishSystemModelRequest} from "../../domain/usecases/publish-system-model.js";
import {
  publishSystemModelCommand,
  type ModelPublishCommandDependencies,
  type OnnxModelValidator,
  type SystemModelPublisher,
} from "./model-publish-command.js";
import {type ModelPublishOptions} from "./model-publish-options.js";

test("checks a model without persisting during a dry run", async () => {
  const events: string[] = [];
  const outcome = await publishSystemModelCommand(options({dryRun: true}), dependencies(events));

  assert.equal(outcome.dryRun, true);
  assert.deepEqual(events, ["contract", "onnx", "artifact", "check"]);
});

test("publishes a verified system model", async () => {
  const events: string[] = [];
  const outcome = await publishSystemModelCommand(options(), dependencies(events));

  assert.equal(outcome.entry.id, "model");
  assert.deepEqual(events, ["contract", "onnx", "artifact", "publish"]);
});

test("stops before reading the artifact when the contract check fails", async () => {
  const events: string[] = [];
  const failing: ModelContractCheck = {
    validate: async () => {
      throw new Error("Eingang input: image.resize: Der Parameter width fehlt.");
    },
  };

  await assert.rejects(publishSystemModelCommand(options(), {...dependencies(events), contractValidator: failing}), /width fehlt/);
  assert.deepEqual(events, []);
});

test("passes the replace-version choice to the publisher", async () => {
  const publisher = new Publisher([]);
  await publishSystemModelCommand(options({replaceVersion: true}), {...dependencies([]), publisher});

  assert.equal(publisher.requests[0]?.replaceVersion, true);
});

test("passes weight files and resources of the options to the artifact", async () => {
  const requested: unknown[] = [];
  await publishSystemModelCommand({...options(), externalDataPaths: ["dir/weights.bin"], resources: [{name: "labels", path: "labels.json"}]}, {
    ...dependencies([]),
    artifactFromFile: async (file) => {
      requested.push(file);
      return artifact();
    },
  });

  assert.deepEqual(requested, [{
    path: "model.onnx", artifactId: "model", versionId: "1",
    externalDataPaths: ["dir/weights.bin"], resources: [{name: "labels", path: "labels.json"}],
  }]);
});

class Publisher implements SystemModelPublisher {
  readonly requests: PublishSystemModelRequest[] = [];

  constructor(private readonly events: string[]) {}

  async check(request: PublishSystemModelRequest): Promise<void> {
    this.requests.push(request);
    this.events.push("check");
  }

  async execute(request: PublishSystemModelRequest): Promise<ModelCatalogEntry> {
    this.requests.push(request);
    this.events.push("publish");
    return request.entry;
  }
}

function dependencies(events: string[]): ModelPublishCommandDependencies {
  const onnxValidator: OnnxModelValidator = {validate: async () => void events.push("onnx")};
  return {
    publisher: new Publisher(events),
    contractValidator: {validate: async () => void events.push("contract")},
    onnxValidator,
    manifestFromFile: async () => manifest(),
    artifactFromFile: async () => {
      events.push("artifact");
      return artifact();
    },
  };
}

function artifact(): ModelArtifactPublication {
  return {
    reference: {
      artifactId: "model", versionId: "1", format: "onnx", contentType: "application/onnx",
      sizeBytes: 1, sha256: "0".repeat(64),
    },
    content: bytes(),
  };
}

function manifest() {
  return {
    id: "model", title: "Modell", description: "Beschreibung", task: "image-classification" as const, languages: [], tags: ["bild"],
    artifact: {artifactId: "model", versionId: "1"}, contract: contract(),
  };
}

function options(overrides: Partial<ModelPublishOptions> = {}): ModelPublishOptions {
  return {
    projectId: "project", manifestPath: "model.json", artifactPath: "model.onnx",
    externalDataPaths: [], resources: [], pythonExecutable: "python3", dryRun: false, replaceVersion: false,
    ...overrides,
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
