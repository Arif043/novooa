import assert from "node:assert/strict";
import test from "node:test";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {ModelTagVocabulary} from "../../domain/entities/model-tag-vocabulary.js";
import {modelSearchHitFrom} from "./model-search-hit.js";

const vocabulary = new ModelTagVocabulary([{key: "animals", labels: {en: "Animals", de: "Tiere"}}]);

test("maps a catalog entry to a compact hit without artifact details", () => {
  const hit = modelSearchHitFrom(entry(), vocabulary);

  assert.deepEqual(hit, {
    modelId: "mobilenet-v3",
    title: "Bildklassifikation",
    description: "Ordnet Bilder Kategorien zu.",
    task: "image-classification",
    topics: ["Tiere", "altes-tag"],
    languages: [],
    inputs: ["image (image)"],
    outputs: ["value (json)"],
    origin: "global",
  });
  assert.equal("artifactReference" in hit, false);
});

function entry(): ModelCatalogEntry {
  return {
    id: "mobilenet-v3",
    title: "MobileNet V3",
    description: "Classifies images.",
    translations: {de: {title: "Bildklassifikation", description: "Ordnet Bilder Kategorien zu."}},
    task: "image-classification",
    languages: [],
    tags: ["animals", "altes-tag"],
    scope: {type: "system"},
    runtime: "onnx",
    artifactReference: {
      artifactId: "a", versionId: "1", format: "onnx",
      contentType: "application/onnx", sizeBytes: 1, sha256: "a".repeat(64),
    },
    contract: {
      inputs: [{name: "image", source: "image", dataType: "float32", shape: [1, 3, 224, 224], transformations: []}],
      outputs: [{
        name: "scores", dataType: "float32", shape: [1, 1000], semantic: "classification.scores",
        transformations: [], workflowOutput: {name: "value", type: "json", mapping: "$tensor"},
      }],
    },
  };
}
