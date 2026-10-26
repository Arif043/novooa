import assert from "node:assert/strict";
import {readdir} from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import {type ModelArtifactReference} from "../../domain/entities/model-artifact-reference.js";
import {systemModelEntry, systemModelManifestFromFile} from "./system-model-manifest.js";

const repositoryRoot = path.resolve(__dirname, "../../../../../..");

test("every shipped model manifest can be published", async () => {
  const manifests = await shippedManifestPaths();
  assert.ok(manifests.some((manifest) => manifest.endsWith("model.json")));
  for (const manifestPath of manifests) {
    const manifest = await systemModelManifestFromFile(manifestPath).catch((error: unknown) => {
      throw new Error(`${path.relative(repositoryRoot, manifestPath)}: ${String(error)}`);
    });
    assert.doesNotThrow(() => systemModelEntry(manifest, reference(manifest.artifact)), manifestPath);
  }
});

async function shippedManifestPaths(): Promise<readonly string[]> {
  const systemModels = path.join(repositoryRoot, "local-runtime", "system-models");
  const catalogModels = path.join(repositoryRoot, "models");
  const systemFiles = (await readdir(systemModels)).filter((name) => name.endsWith(".json"));
  const catalogFiles = (await readdir(catalogModels, {recursive: true})).filter((name) => path.basename(name) === "model.json");
  return [
    ...systemFiles.map((name) => path.join(systemModels, name)),
    ...catalogFiles.map((name) => path.join(catalogModels, name)),
  ];
}

function reference(artifact: {artifactId: string; versionId: string}): ModelArtifactReference {
  return {...artifact, format: "onnx", contentType: "application/onnx", sizeBytes: 1, sha256: "0".repeat(64)};
}
