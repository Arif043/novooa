import {
  type ModelInputValue,
} from "../entities/model-input-source.js";
import {type ModelTensorDataType} from "../entities/model-contract.js";

export type ModelInferenceRequest = {
  teamId: string;
  modelId: string;
  inputs: readonly ModelInputValue[];
};

export type ModelInferenceOutput = {
  name: string;
  semantic: string;
  dataType: ModelTensorDataType;
  shape: readonly number[];
  bytes: Uint8Array;
};

export type ModelInferenceResult = {
  modelId: string;
  outputs: readonly ModelInferenceOutput[];
};

export interface ModelInference {
  execute(request: ModelInferenceRequest): Promise<ModelInferenceResult>;
}
