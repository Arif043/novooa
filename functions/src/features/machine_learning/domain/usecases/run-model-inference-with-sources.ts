import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";
import {
  type ModelInference,
  type ModelInferenceRequest,
  type ModelInferenceResult,
} from "../repositories/model-inference.js";
import {PrepareModelInputs} from "./prepare-model-inputs.js";
import {RunModelInference} from "./run-model-inference.js";
import {ModelOutputPostprocessor} from "../services/model-output-postprocessor.js";

export class RunModelInferenceWithSources implements ModelInference {
  constructor(
    private readonly catalog: ModelCatalog,
    private readonly prepareModelInputs: PrepareModelInputs,
    private readonly runModelInference: RunModelInference,
    private readonly outputPostprocessor = new ModelOutputPostprocessor(),
  ) {}

  async execute(request: ModelInferenceRequest): Promise<ModelInferenceResult> {
    const model = await this.modelFor(request.teamId, request.modelId);
    const inputs = await this.prepareModelInputs.execute(model.contract, request.inputs);
    const outputs = await this.runModelInference.execute({model, inputs});
    return resultFor(model, outputs, request.outputParameters ?? [], this.outputPostprocessor);
  }

  private async modelFor(teamId: string, modelId: string) {
    required(teamId, "Die Team-ID fehlt.");
    required(modelId, "Die Modell-ID fehlt.");
    const model = await this.catalog.findAvailableFor(teamId, modelId);
    if (model === null) throw new Error("Das Modell ist nicht verfügbar.");
    return model;
  }
}

function resultFor(
  model: ModelCatalogEntry,
  tensors: Awaited<ReturnType<RunModelInference["execute"]>>,
  parameterValues: NonNullable<ModelInferenceRequest["outputParameters"]>,
  postprocessor: ModelOutputPostprocessor,
): ModelInferenceResult {
  const semantics = new Map(model.contract.outputs.map((output) => [
    output.name,
    output.semantic,
  ]));
  const definitions = new Map(model.contract.outputs.map((output) => [output.name, output]));
  return {
    modelId: model.id,
    outputs: tensors.map((tensor) => {
      const definition = definitions.get(tensor.name)!;
      const processed = postprocessor.process(definition, tensor, parameterValues);
      return {
        ...tensor,
        semantic: semantics.get(tensor.name)!,
        workflowOutput: processed.workflowOutput,
        value: processed.value,
      };
    }),
  };
}

function required(value: string, message: string): void {
  if (value.trim().length === 0) throw new Error(message);
}
