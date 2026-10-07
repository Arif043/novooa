import assert from "node:assert/strict";
import test from "node:test";
import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";
import {RegisterModelCatalogEntry} from "./register-model-catalog-entry.js";

test("validates an entry before saving it in the catalog", async () => {
  const catalog = new RecordingModelCatalog();
  const useCase = new RegisterModelCatalogEntry(catalog);

  await useCase.execute(validEntry());

  assert.equal(catalog.saved?.id, "mobilenet-v3");
});

test("does not persist an entry with an invalid artifact", async () => {
  const catalog = new RecordingModelCatalog();
  const useCase = new RegisterModelCatalogEntry(catalog);
  const entry = validEntry();

  await assert.rejects(() => useCase.execute({
    ...entry,
    artifactReference: {...entry.artifactReference, sizeBytes: 0},
  }));
  assert.equal(catalog.saved, null);
});

class RecordingModelCatalog implements ModelCatalog {
  saved: ModelCatalogEntry | null = null;

  async save(entry: ModelCatalogEntry): Promise<void> {
    this.saved = entry;
  }

  async listAvailableFor(): Promise<readonly ModelCatalogEntry[]> {
    return [];
  }

  async findAvailableFor(): Promise<ModelCatalogEntry | null> {
    return null;
  }
}

function validEntry(): ModelCatalogEntry {
  return {
    id: "mobilenet-v3",
    title: "MobileNet V3",
    description: "Klassifiziert Bilder in vordefinierte Kategorien.",
    task: "image-classification",
    languages: [],
    tags: ["bild", "klassifikation"],
    scope: {type: "system"},
    runtime: "onnx",
    artifactReference: {
      artifactId: "mobilenet-v3-artifact",
      versionId: "1",
      format: "onnx",
      contentType: "application/onnx",
      sizeBytes: 1024,
      sha256: "a".repeat(64),
    },
    contract: {
      inputs: [{
        name: "image",
        source: "image",
        dataType: "float32",
        shape: ["dynamic", 3, 224, 224],
        transformations: [],
      }],
      outputs: [{
        name: "scores",
        dataType: "float32",
        shape: ["dynamic", 1000],
        semantic: "classification.scores",
        transformations: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"},
      }],
    },
  };
}
