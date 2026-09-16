import {type ModelTensor, validateTensorsForContract} from "../entities/model-tensor.js";
import {type ModelArtifactReader} from "../repositories/model-artifact-reader.js";
import {
  type ModelInferenceRuntime,
  type ModelRuntimeOutput,
} from "../repositories/model-inference-runtime.js";
import {type ModelOutputParameterValue} from "../repositories/model-inference.js";
import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";

export type RunModelInferenceRequest = {
  readonly model: ModelCatalogEntry;
  readonly inputs: readonly ModelTensor[];
  readonly outputParameters?: readonly ModelOutputParameterValue[];
};

export class RunModelInference {
  constructor(
    private readonly artifactReader: ModelArtifactReader,
    private readonly runtime: ModelInferenceRuntime,
  ) {}

  async execute(request: RunModelInferenceRequest): Promise<readonly ModelRuntimeOutput[]> {
    validateTensorsForContract(request.inputs, request.model.contract.inputs, "Eingabe");
    const artifact = await this.artifactReader.read(request.model.artifactReference);
    const outputs = await this.runtime.execute({...request, artifact});
    validateTensorsForContract(outputs.map((output) => output.tensor), request.model.contract.outputs, "Ausgabe");
    return outputs;
  }
}
