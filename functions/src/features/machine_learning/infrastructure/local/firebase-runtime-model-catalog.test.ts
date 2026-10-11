import assert from "node:assert/strict";
import test from "node:test";
import {systemModelEntry, systemModelManifestFromUnknown} from "../cli/system-model-manifest.js";
import {modelCatalogEntryData} from "../model-catalog-entry-codec.js";
import {FirebaseRuntimeModelCatalog, type RuntimeCollectionReader} from "./firebase-runtime-model-catalog.js";

test("loads only system models and keeps their weight files", async () => {
  const catalog = new FirebaseRuntimeModelCatalog(new Reader([
    {id: "system-model", data: modelData()},
    {id: "team-model", data: {...modelData(), scope: "team", teamId: "team-1"}},
  ]));

  const models = await catalog.list();

  assert.equal(models.length, 1);
  assert.equal(models[0]?.entry.id, "system-model");
  assert.deepEqual(models[0]?.entry.artifactReference.externalData, [{name: "model.onnx.data", sizeBytes: 8, sha256: "1".repeat(64)}]);
});

test("finds a system model by its id", async () => {
  const catalog = new FirebaseRuntimeModelCatalog(new Reader([{id: "system-model", data: modelData()}]));

  assert.equal((await catalog.find("system-model"))?.entry.id, "system-model");
  assert.equal(await catalog.find("unknown"), null);
});

class Reader implements RuntimeCollectionReader {
  constructor(private readonly documents: readonly {id: string; data: Record<string, unknown>}[]) {}

  async listCollection(collectionName: string): Promise<readonly {id: string; data: Record<string, unknown>}[]> {
    assert.equal(collectionName, "modelCatalog");
    return this.documents;
  }
}

function modelData(): Record<string, unknown> {
  const entry = systemModelEntry(systemModelManifestFromUnknown({
    id: "system-model",
    title: "Systemmodell",
    description: "Ein Modell aus dem globalen Katalog.",
    task: "image-classification",
    languages: [],
    tags: ["test"],
    artifact: {artifactId: "system-model", versionId: "1"},
    contract: {
      inputs: [{name: "input", source: "tensor", dataType: "uint8", shape: [1], transformations: []}],
      outputs: [{
        name: "output", dataType: "uint8", shape: [1], semantic: "classification.scores", transformations: [],
        workflowOutput: {name: "value", type: "json", mapping: "$tensor"},
      }],
    },
  }), {
    artifactId: "system-model",
    versionId: "1",
    format: "onnx",
    contentType: "application/onnx",
    sizeBytes: 4,
    sha256: "0".repeat(64),
    externalData: [{name: "model.onnx.data", sizeBytes: 8, sha256: "1".repeat(64)}],
  });
  return modelCatalogEntryData(entry);
}
