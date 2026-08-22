import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelTensor} from "../entities/model-tensor.js";

export type ModelRuntimeRequest = {
  model: ModelCatalogEntry;
  artifact: Uint8Array;
  inputs: readonly ModelTensor[];
};

export interface ModelInferenceRuntime {
  execute(request: ModelRuntimeRequest): Promise<readonly ModelTensor[]>;
}
