import assert from "node:assert/strict";
import test from "node:test";
import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelArtifactPublisher} from "../repositories/model-artifact-publisher.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";
import {PublishSystemModel} from "./publish-system-model.js";

test("publishes the artifact before registering a system model", async () => {
  const events: string[] = [];
  const publisher = new Publisher(events);
  const catalog = new Catalog(events);
  const entry = systemEntry();

  const published = await new PublishSystemModel(publisher, catalog).execute({
    entry,
    artifact: {reference: entry.artifactReference, content: bytes()},
  });

  assert.equal(published.id, entry.id);
  assert.deepEqual(events, ["artifact", "catalog"]);
});

test("rejects a team model before uploading its artifact", async () => {
  const events: string[] = [];
  const entry = {...systemEntry(), scope: {type: "team" as const, teamId: "team-1"}};

  await assert.rejects(
    new PublishSystemModel(new Publisher(events), new Catalog(events)).execute({
      entry, artifact: {reference: entry.artifactReference, content: bytes()},
    }),
    /nur Systemmodelle/,
  );
  assert.deepEqual(events, []);
});

class Publisher implements ModelArtifactPublisher {
  constructor(private readonly events: string[]) {}

  async publish(): Promise<void> {
    this.events.push("artifact");
  }
}

class Catalog implements ModelCatalog {
  constructor(private readonly events: string[]) {}

  async save(): Promise<void> {
    this.events.push("catalog");
  }

  async listAvailableFor(): Promise<readonly ModelCatalogEntry[]> {
    return [];
  }

  async findAvailableFor(): Promise<ModelCatalogEntry | null> {
    return null;
  }
}

function systemEntry(): ModelCatalogEntry {
  return {
    id: "classifier", title: "Classifier", description: "Testmodell", tags: ["test"],
    scope: {type: "system"}, runtime: "onnx",
    artifactReference: {
      artifactId: "classifier", versionId: "1", format: "onnx", contentType: "application/onnx",
      sizeBytes: 1, sha256: "0".repeat(64),
    },
    contract: {
      inputs: [{name: "input", source: "tensor", dataType: "uint8", shape: [1], preprocessing: []}],
      outputs: [{name: "output", semantic: "classification.scores", dataType: "uint8", shape: [1], postprocessing: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"}}],
    },
  };
}

async function* bytes(): AsyncGenerator<Uint8Array> {
  yield Uint8Array.from([1]);
}
