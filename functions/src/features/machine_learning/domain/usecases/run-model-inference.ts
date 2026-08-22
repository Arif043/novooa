import {type ModelTensor, validateTensorsForContract} from "../entities/model-tensor.js";
import {type ModelArtifactReader} from "../repositories/model-artifact-reader.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";
import {type ModelInferenceRuntime} from "../repositories/model-inference-runtime.js";

export type RunModelInferenceRequest = {
  teamId: string;
  modelId: string;
  inputs: readonly ModelTensor[];
};

export class RunModelInference {
  constructor(
    private readonly catalog: ModelCatalog,
    private readonly artifactReader: ModelArtifactReader,
    private readonly runtime: ModelInferenceRuntime,
  ) {}

  async execute(request: RunModelInferenceRequest): Promise<readonly ModelTensor[]> {
    required(request.teamId, "Die Team-ID fehlt.");
    required(request.modelId, "Die Modell-ID fehlt.");
    const model = await this.modelFor(request.teamId, request.modelId);
    validateTensorsForContract(request.inputs, model.contract.inputs, "Eingabe");
    const artifact = await this.artifactReader.read(model.artifactReference);
    const outputs = await this.runtime.execute({model, artifact, inputs: request.inputs});
    validateTensorsForContract(outputs, model.contract.outputs, "Ausgabe");
    return outputs;
  }

  private async modelFor(teamId: string, modelId: string) {
    const model = await this.catalog.findAvailableFor(teamId, modelId);
    if (model === null) throw new Error("Das Modell ist nicht verfügbar.");
    return model;
  }
}

function required(value: string, message: string): void {
  if (value.trim().length === 0) throw new Error(message);
}
