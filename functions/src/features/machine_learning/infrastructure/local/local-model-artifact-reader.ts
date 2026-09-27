import {readFile} from "node:fs/promises";
import path from "node:path";
import {type ModelArtifactReference, type ModelArtifactResourceReference} from "../../domain/entities/model-artifact-reference.js";
import {type ModelArtifactReader} from "../../domain/repositories/model-artifact-reader.js";
import {verifyModelArtifact} from "../model-artifact-integrity.js";
import {modelArtifactResourceStoragePathFor, modelArtifactStoragePathFor} from "../model-artifact-storage-path.js";

export class LocalModelArtifactReader implements ModelArtifactReader {
  constructor(private readonly rootDirectory: string) {}

  async read(reference: ModelArtifactReference): Promise<Uint8Array> {
    const pathToArtifact = path.join(
      this.rootDirectory,
      modelArtifactStoragePathFor(reference),
    );
    return verifyModelArtifact(reference, await readFile(pathToArtifact));
  }

  async readResource(reference: ModelArtifactReference, resource: ModelArtifactResourceReference): Promise<Uint8Array> {
    return verifyModelArtifact({...reference, ...resource}, await readFile(path.join(this.rootDirectory, modelArtifactResourceStoragePathFor(reference, resource))));
  }
}
