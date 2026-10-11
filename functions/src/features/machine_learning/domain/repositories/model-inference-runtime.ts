import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelOutputValue} from "../entities/model-output-value.js";
import {type ModelTensor} from "../entities/model-tensor.js";

export type ModelRuntimeOutput = ModelTensor & {
  readonly tensor: ModelTensor;
  readonly transformationValues: Readonly<Record<string, ModelOutputValue>>;
};

/** Die Runtime erhält nur den Katalogeintrag; wie sie an die Modelldateien kommt, ist ihre Sache. */
export type ModelRuntimeRequest = {
  readonly model: ModelCatalogEntry;
  readonly inputs: readonly ModelTensor[];
};

export type ModelRuntimePreparationRequest = Pick<ModelRuntimeRequest, "model">;

export interface ModelInputPreparationRuntime {
  prepareInputs(request: ModelRuntimePreparationRequest): Promise<string>;
}

export interface ModelInferenceRuntime {
  execute(request: ModelRuntimeRequest): Promise<readonly ModelRuntimeOutput[]>;
}
