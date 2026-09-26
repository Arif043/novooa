import assert from "node:assert/strict";
import test from "node:test";
import {systemModelEntry, systemModelManifestFromUnknown} from "../cli/system-model-manifest.js";
import {modelCatalogEntryData} from "../model-catalog-entry-codec.js";
import {FirebaseRuntimeModelCatalog, type RuntimeCollectionReader} from "./firebase-runtime-model-catalog.js";

test("loads only system models together with their internal distribution", async () => {
  const catalog = new FirebaseRuntimeModelCatalog(new Reader([
    {id: "system-model", data: {...modelData(), distribution: distribution()}},
    {id: "team-model", data: {...modelData(), scope: "team", teamId: "team-1", distribution: distribution()}},
  ]));

  const models = await catalog.list();

  assert.equal(models.length, 1);
  assert.equal(models[0]?.entry.id, "system-model");
  assert.deepEqual(models[0]?.distribution, distribution());
});

test("rejects a global model without a valid distribution", async () => {
  const catalog = new FirebaseRuntimeModelCatalog(new Reader([
    {id: "system-model", data: modelData()},
  ]));

  await assert.rejects(catalog.list(), /Modell-Distribution/);
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
  });
  return modelCatalogEntryData(entry);
}

function distribution() {
  return {
    type: "huggingFace",
    repository: "novooa/system-model",
    revision: "a".repeat(40),
    path: "model.onnx",
  };
}
