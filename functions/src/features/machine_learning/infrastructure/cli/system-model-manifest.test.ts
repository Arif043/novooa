import assert from "node:assert/strict";
import test from "node:test";
import {systemModelEntry, systemModelManifestFromUnknown} from "./system-model-manifest.js";

test("maps an operator manifest to a system catalog entry", () => {
  const manifest = systemModelManifestFromUnknown(manifestData());
  const entry = systemModelEntry(manifest, reference());

  assert.equal(entry.scope.type, "system");
  assert.equal(entry.artifactReference.sha256, "0".repeat(64));
});

test("carries manifest translations into the catalog entry and ignores formerly translated tags", () => {
  const data = manifestData();
  data.translations = {de: {title: "Modell", description: "Beschreibung", tags: ["bild"]}, "pt-BR": {title: "Modelo", description: "Descrição"}};
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

  const duplicateTags = {...manifestData(), tags: ["bild", "Bild"]};
  assert.throws(() => systemModelEntry(systemModelManifestFromUnknown(duplicateTags), reference()), /eindeutig/);
});

test("rejects a manifest without an artifact version", () => {
  const data = manifestData();
  data.artifact = {artifactId: "model"};
  assert.throws(() => systemModelManifestFromUnknown(data), /Version fehlt/);
});

test("carries the solved task and the supported languages into the entry", () => {
  const data = {...manifestData(), task: "text-to-speech", languages: ["de", "en-GB"]};
  const entry = systemModelEntry(systemModelManifestFromUnknown(data), reference());

  assert.equal(entry.task, "text-to-speech");
  assert.deepEqual(entry.languages, ["de", "en-GB"]);
});

test("requires a known task and treats missing languages as language independent", () => {
  const {task: _task, ...withoutTask} = manifestData();
  assert.throws(() => systemModelManifestFromUnknown(withoutTask), /Modellaufgabe.*Erlaubt sind: .*anomaly-detection/);
  assert.throws(() => systemModelManifestFromUnknown({...manifestData(), task: "bilderkennung"}), /Modellaufgabe/);

  const ownTask = systemModelManifestFromUnknown({...manifestData(), task: "optical-character-recognition"});
  assert.equal(ownTask.task, "optical-character-recognition");

  const {languages: _languages, ...withoutLanguages} = manifestData();
  assert.deepEqual(systemModelManifestFromUnknown(withoutLanguages).languages, []);
});

test("rejects an invalid or duplicate language", () => {
  const invalid = {...manifestData(), languages: ["deutsch!"]};
  assert.throws(() => systemModelEntry(systemModelManifestFromUnknown(invalid), reference()), /Sprachcode/);
  const duplicate = {...manifestData(), languages: ["de", "de"]};
  assert.throws(() => systemModelEntry(systemModelManifestFromUnknown(duplicate), reference()), /eindeutig/);
});

function manifestData(): Record<string, unknown> {
  return {
    id: "model", title: "Modell", description: "Beschreibung", task: "image-classification", languages: [], tags: ["bild"],
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
