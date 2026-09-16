import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelOutputValue} from "../entities/model-output-value.js";
import {type ModelTensor} from "../entities/model-tensor.js";

export type ModelRuntimeOutput = ModelTensor & {
  readonly tensor: ModelTensor;
  readonly transformationValues: Readonly<Record<string, ModelOutputValue>>;
};

export type ModelRuntimeRequest = {
  readonly model: ModelCatalogEntry;
  readonly artifact: Uint8Array;
  readonly inputs: readonly ModelTensor[];
  readonly outputParameters?: readonly {
    readonly outputName: string;
    readonly name: string;
    readonly value: number;
  }[];
};

export interface ModelInferenceRuntime {
  execute(request: ModelRuntimeRequest): Promise<readonly ModelRuntimeOutput[]>;
}
