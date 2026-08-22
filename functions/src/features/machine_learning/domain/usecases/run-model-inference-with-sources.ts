import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelInput} from "../entities/model-contract.js";
import {
  type ModelInputSource,
  type ModelInputValue,
} from "../entities/model-input-source.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";
import {
  type ModelInference,
  type ModelInferenceRequest,
  type ModelInferenceResult,
} from "../repositories/model-inference.js";
import {PrepareModelInputs} from "./prepare-model-inputs.js";
import {RunModelInference} from "./run-model-inference.js";

export class RunModelInferenceWithSources implements ModelInference {
  constructor(
    private readonly catalog: ModelCatalog,
    private readonly prepareModelInputs: PrepareModelInputs,
    private readonly runModelInference: RunModelInference,
  ) {}

  async execute(request: ModelInferenceRequest): Promise<ModelInferenceResult> {
    const model = await this.modelFor(request.teamId, request.modelId);
    const sources = sourcesFor(model.contract.inputs, request.inputs);
    const inputs = await this.prepareModelInputs.execute(model.contract, sources);
    const outputs = await this.runModelInference.execute({model, inputs});
    return resultFor(model, outputs);
  }

  private async modelFor(teamId: string, modelId: string) {
    required(teamId, "Die Team-ID fehlt.");
    required(modelId, "Die Modell-ID fehlt.");
    const model = await this.catalog.findAvailableFor(teamId, modelId);
    if (model === null) throw new Error("Das Modell ist nicht verfügbar.");
    return model;
  }
}

function sourcesFor(
  inputs: readonly ModelInput[],
  values: readonly ModelInputValue[],
): readonly ModelInputSource[] {
  if (values.length !== inputs.length) {
    throw new Error("Die Anzahl der Modelleingaben stimmt nicht mit dem Modellvertrag überein.");
  }
  return inputs.map((input, index) => ({name: input.name, ...values[index]}));
}

function resultFor(
  model: ModelCatalogEntry,
  tensors: Awaited<ReturnType<RunModelInference["execute"]>>,
): ModelInferenceResult {
  const semantics = new Map(model.contract.outputs.map((output) => [
    output.name,
    output.semantic,
  ]));
  return {
    modelId: model.id,
    outputs: tensors.map((tensor) => ({...tensor, semantic: semantics.get(tensor.name)!})),
  };
}

function required(value: string, message: string): void {
  if (value.trim().length === 0) throw new Error(message);
}
