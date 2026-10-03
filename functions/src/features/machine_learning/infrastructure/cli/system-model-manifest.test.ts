import assert from "node:assert/strict";
import test from "node:test";
import {systemModelEntry, systemModelManifestFromUnknown} from "./system-model-manifest.js";

test("maps an operator manifest to a system catalog entry", () => {
  const manifest = systemModelManifestFromUnknown(manifestData());
  const entry = systemModelEntry(manifest, reference());

  assert.equal(entry.scope.type, "system");
  assert.equal(entry.artifactReference.sha256, "0".repeat(64));
});

test("carries manifest translations into the catalog entry", () => {
  const data = manifestData();
  data.translations = {de: {title: "Modell", description: "Beschreibung"}, "pt-BR": {title: "Modelo", description: "Descrição"}};
  const entry = systemModelEntry(systemModelManifestFromUnknown(data), reference());

  assert.deepEqual(entry.translations?.de, {title: "Modell", description: "Beschreibung"});
  assert.equal(entry.translations?.["pt-BR"]?.title, "Modelo");
});

test("keeps manifests without translations valid", () => {
  const entry = systemModelEntry(systemModelManifestFromUnknown(manifestData()), reference());
  assert.equal(entry.translations, undefined);
});

test("rejects an invalid translation locale or an empty translated title", () => {
  const badLocale = manifestData();
  badLocale.translations = {"not a locale": {title: "A", description: "B"}};
  assert.throws(() => systemModelEntry(systemModelManifestFromUnknown(badLocale), reference()), /Sprachcode/);

  const emptyTitle = manifestData();
  emptyTitle.translations = {de: {title: " ", description: "B"}};
  assert.throws(() => systemModelManifestFromUnknown(emptyTitle), /übersetzte Modellname/);
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
      inputs: [{name: "input", source: "tensor", dataType: "uint8", shape: [1], transformations: []}],
      outputs: [{name: "output", semantic: "test", dataType: "uint8", shape: [1], transformations: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"}}],
    },
  };
}

function reference() {
  return {
    artifactId: "model", versionId: "1", format: "onnx" as const, contentType: "application/onnx",
    sizeBytes: 1, sha256: "0".repeat(64),
  };
}
