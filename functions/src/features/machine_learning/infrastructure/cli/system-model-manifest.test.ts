import assert from "node:assert/strict";
import test from "node:test";
import {systemModelEntry, systemModelManifestFromUnknown} from "./system-model-manifest.js";

test("maps an operator manifest to a system catalog entry", () => {
  const manifest = systemModelManifestFromUnknown(manifestData());
  const entry = systemModelEntry(manifest, reference());

  assert.equal(entry.scope.type, "system");
  assert.equal(entry.artifactReference.sha256, "0".repeat(64));
});

test("rejects a manifest without an artifact version", () => {
  const data = manifestData();
  data.artifact = {artifactId: "model"};
  assert.throws(() => systemModelManifestFromUnknown(data), /Version fehlt/);
});

function manifestData(): Record<string, unknown> {
  return {
    id: "model", title: "Modell", description: "Beschreibung", tags: ["bild"],
    artifact: {artifactId: "model", versionId: "1"},
    contract: {
      inputs: [{name: "input", source: "tensor", dataType: "uint8", shape: [1], preprocessing: []}],
      outputs: [{name: "output", semantic: "test", dataType: "uint8", shape: [1], postprocessing: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"}}],
    },
  };
}

function reference() {
  return {
    artifactId: "model", versionId: "1", format: "onnx" as const, contentType: "application/onnx",
    sizeBytes: 1, sha256: "0".repeat(64),
  };
}
