import assert from "node:assert/strict";
import {mkdtemp, rm, writeFile} from "node:fs/promises";
import {tmpdir} from "node:os";
import path from "node:path";
import test from "node:test";
import {modelArtifactFromFile} from "./model-artifact-from-file.js";

test("creates a verified artifact reference and a repeatable content stream", async () => {
  const directory = await mkdtemp(path.join(tmpdir(), "novooa-model-artifact-"));
  const artifactPath = path.join(directory, "model.onnx");
  try {
    await writeFile(artifactPath, Uint8Array.from([1, 2, 3]));
    const artifact = await modelArtifactFromFile({path: artifactPath, artifactId: "model", versionId: "1"});

    assert.equal(artifact.reference.sizeBytes, 3);
    assert.equal(artifact.reference.sha256, "039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81");
    assert.deepEqual(await allBytes(artifact.content), [1, 2, 3]);
  } finally {
    await rm(directory, {recursive: true, force: true});
  }
});

async function allBytes(content: AsyncIterable<Uint8Array>): Promise<number[]> {
  const bytes: number[] = [];
  for await (const chunk of content) bytes.push(...chunk);
  return bytes;
}
