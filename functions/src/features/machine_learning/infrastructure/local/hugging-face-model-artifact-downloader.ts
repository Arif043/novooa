import {createHash} from "node:crypto";
import {stat} from "node:fs/promises";
import {createReadStream as openFile} from "node:fs";
import {downloadFileToCacheDir} from "@huggingface/hub";
import {type ModelArtifactReference} from "../../domain/entities/model-artifact-reference.js";
import {type ModelArtifactPublication} from "../../domain/repositories/model-artifact-publisher.js";
import {type ModelArtifactDistribution} from "../model-artifact-distribution.js";

export class HuggingFaceModelArtifactDownloader {
  constructor(
    private readonly cacheDirectory: string,
    private readonly token?: string,
  ) {}

  async download(
    reference: ModelArtifactReference,
    distribution: ModelArtifactDistribution,
  ): Promise<ModelArtifactPublication> {
    if (distribution.type !== "huggingFace") throw new Error("Die Modell-Distribution wird nicht unterstützt.");
    const filePath = await downloadFileToCacheDir({
      repo: {type: "model", name: distribution.repository},
      path: distribution.path,
      revision: distribution.revision,
      cacheDir: this.cacheDirectory,
      accessToken: this.token,
    });
    await verifyDownloadedFile(filePath, reference);
    return {reference, content: openFile(filePath)};
  }
}

async function verifyDownloadedFile(
  filePath: string,
  reference: ModelArtifactReference,
): Promise<void> {
  const fileStats = await stat(filePath);
  if (fileStats.size !== reference.sizeBytes) {
    throw new Error("Die heruntergeladene Modellgröße stimmt nicht mit dem Katalog überein.");
  }
  const digest = await sha256(filePath);
  if (digest !== reference.sha256.toLowerCase()) {
    throw new Error("Die Prüfsumme des heruntergeladenen Modells ist ungültig.");
  }
}

async function sha256(filePath: string): Promise<string> {
  const hash = createHash("sha256");
  for await (const chunk of openFile(filePath)) hash.update(chunk);
  return hash.digest("hex");
}
