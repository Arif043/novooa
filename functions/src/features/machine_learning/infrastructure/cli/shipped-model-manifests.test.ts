import assert from "node:assert/strict";
import path from "node:path";
import test from "node:test";
import {type ModelArtifactReference} from "../../domain/entities/model-artifact-reference.js";
import {FileModelTagVocabulary} from "../file-model-tag-vocabulary.js";
import {repositoryRoot, shippedManifestPaths, shippedModelTagsPath} from "./repository-files.js";
import {systemModelEntry, systemModelManifestFromFile} from "./system-model-manifest.js";

const appLocales = ["en", "de", "tr"];

test("every shipped model manifest can be published with known tags", async () => {
  const manifests = await shippedManifestPaths();
  const vocabulary = await new FileModelTagVocabulary(shippedModelTagsPath).load();
  assert.ok(manifests.some((manifest) => manifest.endsWith("model.json")));
  for (const manifestPath of manifests) {
    const label = path.relative(repositoryRoot, manifestPath);
    const manifest = await systemModelManifestFromFile(manifestPath).catch((error: unknown) => {
      throw new Error(`${label}: ${String(error)}`);
    });
    assert.doesNotThrow(() => systemModelEntry(manifest, reference(manifest.artifact)), label);
    assert.doesNotThrow(() => vocabulary.requireKnown(manifest.tags), label);
  }
});

test("every shipped tag is named in all app languages", async () => {
  const vocabulary = await new FileModelTagVocabulary(shippedModelTagsPath).load();
  for (const tag of vocabulary.tags) {
    assert.deepEqual(appLocales.filter((locale) => tag.labels[locale] === undefined), [], tag.key);
  }
});

function reference(artifact: {artifactId: string; versionId: string}): ModelArtifactReference {
  return {...artifact, format: "onnx", contentType: "application/onnx", sizeBytes: 1, sha256: "0".repeat(64)};
}
