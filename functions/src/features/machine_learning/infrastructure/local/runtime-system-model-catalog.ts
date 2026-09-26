import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type ModelArtifactDistribution} from "../model-artifact-distribution.js";

export type RuntimeSystemModel = {
  entry: ModelCatalogEntry;
  distribution: ModelArtifactDistribution;
};

export interface RuntimeSystemModelCatalog {
  list(): Promise<readonly RuntimeSystemModel[]>;
  find(modelId: string): Promise<RuntimeSystemModel | null>;
}
