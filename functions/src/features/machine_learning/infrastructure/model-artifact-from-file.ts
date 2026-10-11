import {createHash} from "node:crypto";
import {createReadStream} from "node:fs";
import {stat} from "node:fs/promises";
import path from "node:path";
import {
  type ModelArtifactFileReference,
  type ModelArtifactReference,
  type ModelArtifactResourceReference,
} from "../domain/entities/model-artifact-reference.js";
import {type ModelArtifactPublication, type PublishedFile} from "../domain/repositories/model-artifact-publisher.js";

export type ModelArtifactFile = {
  path: string;
  artifactId: string;
  versionId: string;
  /** Gewichtsdateien (External Data); ihr Dateiname ist der Name, unter dem das Modell sie erwartet. */
  externalDataPaths?: readonly string[];
  resources?: readonly {name: string; path: string}[];
};

export async function modelArtifactFromFile(artifact: ModelArtifactFile): Promise<ModelArtifactPublication> {
  const externalData = await Promise.all((artifact.externalDataPaths ?? []).map((filePath) => externalDataFile(artifact.path, filePath)));
  const resources = await Promise.all((artifact.resources ?? []).map((resource) => resourceFile(resource)));
  const reference: ModelArtifactReference = {
    artifactId: artifact.artifactId, versionId: artifact.versionId, format: "onnx", contentType: "application/onnx",
    ...await fingerprint(artifact.path),
    ...(resources.length > 0 ? {resources: resources.map((file) => file.reference)} : {}),
    ...(externalData.length > 0 ? {externalData: externalData.map((file) => file.reference)} : {}),
  };
  return {
    reference, content: chunksFrom(artifact.path),
    ...(resources.length > 0 ? {resources} : {}),
    ...(externalData.length > 0 ? {externalData} : {}),
  };
}

async function externalDataFile(modelPath: string, filePath: string): Promise<PublishedFile<ModelArtifactFileReference>> {
  // ONNX Runtime sucht die Gewichte relativ zum Modell; nur so prüft die Vertragsprüfung dasselbe wie die Runtime.
  if (path.dirname(path.resolve(filePath)) !== path.dirname(path.resolve(modelPath))) {
    throw new Error(`Die Gewichtsdatei ${filePath} muss im selben Ordner wie das Modell liegen.`);
  }
  return {reference: {name: path.basename(filePath), ...await fingerprint(filePath)}, content: chunksFrom(filePath)};
}

async function resourceFile(resource: {name: string; path: string}): Promise<PublishedFile<ModelArtifactResourceReference>> {
  const reference = {name: resource.name, contentType: contentTypeFor(resource.path), ...await fingerprint(resource.path)};
  return {reference, content: chunksFrom(resource.path)};
}

async function fingerprint(filePath: string): Promise<{sizeBytes: number; sha256: string}> {
  const details = await stat(filePath);
  if (!details.isFile() || details.size <= 0) throw new Error(`Die Datei ${filePath} fehlt oder ist leer.`);
  const hash = createHash("sha256");
  for await (const chunk of createReadStream(filePath)) hash.update(chunk as Buffer);
  return {sizeBytes: details.size, sha256: hash.digest("hex")};
}

function contentTypeFor(filePath: string): string {
  const types: Record<string, string> = {".json": "application/json", ".txt": "text/plain", ".npy": "application/octet-stream"};
  return types[path.extname(filePath).toLowerCase()] ?? "application/octet-stream";
}

async function* chunksFrom(filePath: string): AsyncGenerator<Uint8Array> {
  for await (const chunk of createReadStream(filePath)) yield chunk as Buffer;
}
