import {type ModelInput} from "../entities/model-contract.js";
import {type ModelInputSource} from "../entities/model-input-source.js";
import {type ModelTensor} from "../entities/model-tensor.js";

export type ModelInputTransformationRequest = {
  input: ModelInput;
  source: ModelInputSource;
};

export interface ModelInputTransformer {
  transform(request: ModelInputTransformationRequest): Promise<ModelTensor>;
}
