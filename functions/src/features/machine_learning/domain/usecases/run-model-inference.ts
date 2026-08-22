import {type ModelTensor, validateTensorsForContract} from "../entities/model-tensor.js";
import {type ModelArtifactReader} from "../repositories/model-artifact-reader.js";
import {type ModelInferenceRuntime} from "../repositories/model-inference-runtime.js";
import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";

export type RunModelInferenceRequest = {
  model: ModelCatalogEntry;
  inputs: readonly ModelTensor[];
};

export class RunModelInference {
  constructor(
    private readonly artifactReader: ModelArtifactReader,
    private readonly runtime: ModelInferenceRuntime,
  ) {}

  async execute(request: RunModelInferenceRequest): Promise<readonly ModelTensor[]> {
    validateTensorsForContract(request.inputs, request.model.contract.inputs, "Eingabe");
    const artifact = await this.artifactReader.read(request.model.artifactReference);
    const outputs = await this.runtime.execute({
      model: request.model,
      artifact,
      inputs: request.inputs,
    });
    validateTensorsForContract(outputs, request.model.contract.outputs, "Ausgabe");
    return outputs;
  }
}
