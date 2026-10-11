import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";

/** Stellt die Dateien eines Modells dort bereit, wo es später ausgeführt wird, ohne es schon zu laden. */
export interface ModelArtifactPrefetcher {
  prefetch(entry: ModelCatalogEntry): Promise<void>;
}
