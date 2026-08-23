import {createHash} from "node:crypto";
import {createReadStream} from "node:fs";
import {stat} from "node:fs/promises";
import {type ModelArtifactReference} from "../domain/entities/model-artifact-reference.js";
import {type ModelArtifactPublication} from "../domain/repositories/model-artifact-publisher.js";

export type ModelArtifactFile = {
  path: string;
  artifactId: string;
  versionId: string;
};

export async function modelArtifactFromFile(
  artifact: ModelArtifactFile,
): Promise<ModelArtifactPublication> {
  return {reference: await referenceFor(artifact), content: chunksFrom(artifact.path)};
}

async function referenceFor(artifact: ModelArtifactFile): Promise<ModelArtifactReference> {
  const sizeBytes = await sizeOf(artifact.path);
  return {
    artifactId: artifact.artifactId, versionId: artifact.versionId, format: "onnx",
    contentType: "application/onnx", sizeBytes, sha256: await sha256For(artifact.path),
  };
}

async function sizeOf(path: string): Promise<number> {
  const details = await stat(path);
  if (!details.isFile() || details.size <= 0) throw new Error("Die ONNX-Datei fehlt oder ist leer.");
  return details.size;
}

async function sha256For(path: string): Promise<string> {
  const hash = createHash("sha256");
  for await (const chunk of createReadStream(path)) hash.update(chunk);
  return hash.digest("hex");
}

async function* chunksFrom(path: string): AsyncGenerator<Uint8Array> {
  for await (const chunk of createReadStream(path)) yield chunk;
}
