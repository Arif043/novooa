import {createHash} from "node:crypto";
import {type ModelArtifactReference} from "../domain/entities/model-artifact-reference.js";
import {modelArtifactDirectoryFor} from "./model-artifact-storage-path.js";

/** Eine Datei eines Modellbündels: `path` relativ zum Modellordner, `storePath` relativ zum Speicher. */
export type ModelBundleFile = {
  readonly path: string;
  readonly sha256: string;
  readonly sizeBytes: number;
  readonly storePath: string;
};

/** Alle Dateien einer Modellversion; der Schlüssel ergibt sich aus Pfaden und Prüfsummen (wie im ML-Dienst). */
export type ModelBundle = {
  readonly key: string;
  readonly files: readonly ModelBundleFile[];
};

export function modelBundleFor(reference: ModelArtifactReference): ModelBundle {
  const directory = modelArtifactDirectoryFor(reference);
  const files = [
    {path: "model.onnx", sha256: reference.sha256, sizeBytes: reference.sizeBytes},
    ...(reference.externalData ?? []).map((file) => ({path: file.name, sha256: file.sha256, sizeBytes: file.sizeBytes})),
    ...(reference.resources ?? []).map((file) => ({path: `resources/${file.name}`, sha256: file.sha256, sizeBytes: file.sizeBytes})),
  ].map((file) => ({...file, sha256: file.sha256.toLowerCase(), storePath: `${directory}/${file.path}`}));
  return {key: modelBundleKey(files), files};
}

export function modelBundleKey(files: readonly Pick<ModelBundleFile, "path" | "sha256">[]): string {
  const lines = [...files]
    .sort((left, right) => (left.path < right.path ? -1 : left.path > right.path ? 1 : 0))
    .map((file) => `${file.path}:${file.sha256}\n`)
    .join("");
  return createHash("sha256").update(lines, "utf8").digest("hex");
}
