import assert from "node:assert/strict";
import test from "node:test";
import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelArtifactPublisher} from "../repositories/model-artifact-publisher.js";
import {type SystemModelRegistry} from "../repositories/system-model-registry.js";
import {PublishSystemModel, SystemModelVersionConflictError} from "./publish-system-model.js";

test("publishes the artifact before registering a system model", async () => {
  const events: string[] = [];
  const entry = systemEntry();

  const published = await new PublishSystemModel(new Publisher(events), new Registry(events)).execute(requestFor(entry));

  assert.equal(published.id, entry.id);
  assert.deepEqual(events, ["artifact", "catalog"]);
});

test("rejects a team model before uploading its artifact", async () => {
  const events: string[] = [];
  const entry = {...systemEntry(), scope: {type: "team" as const, teamId: "team-1"}};

  await assert.rejects(
    new PublishSystemModel(new Publisher(events), new Registry(events)).execute(requestFor(entry)),
    /nur Systemmodelle/,
  );
  assert.deepEqual(events, []);
});

test("republishes the same version of a published model", async () => {
  const events: string[] = [];
  const registry = new Registry(events, systemEntry());

  await new PublishSystemModel(new Publisher(events), registry).execute(requestFor(systemEntry()));

  assert.deepEqual(events, ["artifact", "catalog"]);
});

test("refuses to replace a published version without confirmation", async () => {
  const events: string[] = [];
  const registry = new Registry(events, systemEntry());
  const newer = systemEntry("2");

  await assert.rejects(
    new PublishSystemModel(new Publisher(events), registry).execute(requestFor(newer)),
    (error) => error instanceof SystemModelVersionConflictError && /classifier@1/.test(error.message),
  );
  assert.deepEqual(events, []);
});

test("replaces a published version when confirmed", async () => {
  const events: string[] = [];
  const registry = new Registry(events, systemEntry());

  await new PublishSystemModel(new Publisher(events), registry).execute({...requestFor(systemEntry("2")), replaceVersion: true});

  assert.deepEqual(events, ["artifact", "catalog"]);
});

test("reports a version conflict when only checking", async () => {
  const events: string[] = [];
  const useCase = new PublishSystemModel(new Publisher(events), new Registry(events, systemEntry()));

  await assert.rejects(useCase.check(requestFor(systemEntry("2"))), SystemModelVersionConflictError);
  await useCase.check(requestFor(systemEntry()));
  assert.deepEqual(events, []);
});

class Publisher implements ModelArtifactPublisher {
  constructor(private readonly events: string[]) {}

  async publish(): Promise<void> {
    this.events.push("artifact");
  }
}

class Registry implements SystemModelRegistry {
  constructor(private readonly events: string[], private readonly published: ModelCatalogEntry | null = null) {}

  async findSystemEntry(): Promise<ModelCatalogEntry | null> {
    return this.published;
  }

  async save(): Promise<void> {
    this.events.push("catalog");
  }
}

function requestFor(entry: ModelCatalogEntry) {
  return {entry, artifact: {reference: entry.artifactReference, content: bytes()}};
}

function systemEntry(versionId = "1"): ModelCatalogEntry {
  return {
    id: "classifier", title: "Classifier", description: "Testmodell", task: "image-classification", languages: [], tags: ["test"],
    scope: {type: "system"}, runtime: "onnx",
    artifactReference: {
      artifactId: "classifier", versionId, format: "onnx", contentType: "application/onnx",
      sizeBytes: 1, sha256: "0".repeat(64),
    },
    contract: {
      inputs: [{name: "input", source: "tensor", dataType: "uint8", shape: [1], transformations: []}],
      outputs: [{name: "output", semantic: "classification.scores", dataType: "uint8", shape: [1], transformations: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"}}],
    },
  };
}

async function* bytes(): AsyncGenerator<Uint8Array> {
  yield Uint8Array.from([1]);
}
