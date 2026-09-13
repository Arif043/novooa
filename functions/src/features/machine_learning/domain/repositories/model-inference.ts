import {
  type ModelInputSource,
} from "../entities/model-input-source.js";
import {type ModelTensorDataType} from "../entities/model-contract.js";
import {type ModelWorkflowOutput} from "../entities/model-workflow-output.js";
import {type ModelOutputValue} from "../entities/model-output-value.js";
import {type ModelOutputParameterValue} from "../services/model-output-postprocessor.js";

export type ModelInferenceRequest = {
  teamId: string;
  modelId: string;
  inputs: readonly ModelInputSource[];
  outputParameters?: readonly ModelOutputParameterValue[];
};

export type ModelInferenceOutput = {
  name: string;
  semantic: string;
  dataType: ModelTensorDataType;
  shape: readonly number[];
  bytes: Uint8Array;
  workflowOutput: ModelWorkflowOutput;
  value: ModelOutputValue;
};

export type ModelInferenceResult = {
  modelId: string;
  outputs: readonly ModelInferenceOutput[];
};

export interface ModelInference {
  execute(request: ModelInferenceRequest): Promise<ModelInferenceResult>;
}
