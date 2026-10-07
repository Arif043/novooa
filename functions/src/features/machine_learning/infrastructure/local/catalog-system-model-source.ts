import {type SystemModel, type SystemModelSource} from "../../domain/repositories/system-model-source.js";
import {type ModelArtifactDownloader} from "./local-model-catalog-support.js";
import {type RuntimeSystemModelCatalog} from "./runtime-system-model-catalog.js";

/**
 * Fassade über globalen Katalog (Firestore) und Download (Hugging Face): Die Domain sieht nur
 * Eintrag und „Artefakt holen“, nicht die technische Distribution.
 */
export class CatalogSystemModelSource implements SystemModelSource {
  constructor(
    private readonly catalog: RuntimeSystemModelCatalog,
    private readonly downloader: ModelArtifactDownloader,
  ) {}

  async find(modelId: string): Promise<SystemModel | null> {
    const model = await this.catalog.find(modelId);
    if (model === null || model.entry.scope.type !== "system") return null;
    return {
      entry: model.entry,
      fetchArtifact: () => this.downloader.download(model.entry.artifactReference, model.distribution),
    };
  }
}
