import {type ModelTensor, validateTensorsForContract} from "../entities/model-tensor.js";
import {
  type ModelInferenceRuntime,
  type ModelInputPreparationRuntime,
  type ModelRuntimeOutput,
} from "../repositories/model-inference-runtime.js";
import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";

export type RunModelInferenceRequest = {
  readonly model: ModelCatalogEntry;
  readonly inputs: readonly ModelTensor[];
};

export class RunModelInference {
  constructor(private readonly runtime: ModelInferenceRuntime) {}

  async execute(request: RunModelInferenceRequest): Promise<readonly ModelRuntimeOutput[]> {
    validateTensorsForContract(request.inputs, request.model.contract.inputs, "Eingabe");
    const outputs = await this.runtime.execute(request);
    validateTensorsForContract(outputs.map((output) => output.tensor), request.model.contract.outputs, "Ausgabe");
    return outputs;
  }

  async prepareInputs(model: ModelCatalogEntry): Promise<string | undefined> {
    if (!isPreparationRuntime(this.runtime)) return undefined;
    return this.runtime.prepareInputs({model});
  }
}

function isPreparationRuntime(runtime: ModelInferenceRuntime): runtime is ModelInferenceRuntime & ModelInputPreparationRuntime {
  return "prepareInputs" in runtime && typeof runtime.prepareInputs === "function";
}
