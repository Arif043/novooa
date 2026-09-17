import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";
import {
  type ModelInference,
  type ModelInferenceRequest,
  type ModelInferenceResult,
} from "../repositories/model-inference.js";
import {mapWorkflowOutput} from "../services/workflow-output-mapper.js";
import {resolveModelContractBindings} from "../services/resolve-model-contract-bindings.js";
import {PrepareModelInputs} from "./prepare-model-inputs.js";
import {RunModelInference} from "./run-model-inference.js";

export class RunModelInferenceWithSources implements ModelInference {
  constructor(
    private readonly catalog: ModelCatalog,
    private readonly prepareModelInputs: PrepareModelInputs,
    private readonly runModelInference: RunModelInference,
  ) {}

  async execute(request: ModelInferenceRequest): Promise<ModelInferenceResult> {
    const storedModel = await this.modelFor(request.teamId, request.modelId);
    const model = {
      ...storedModel,
      contract: resolveModelContractBindings(
        storedModel.contract,
        request.transformationBindings,
      ),
    };
    const inputs = await this.prepareModelInputs.execute(model.contract, request.inputs);
    const outputs = await this.runModelInference.execute({
      model,
      inputs,
      outputParameters: request.outputParameters ?? [],
    });
    return resultFor(model, outputs);
  }

  private async modelFor(teamId: string, modelId: string): Promise<ModelCatalogEntry> {
    required(teamId, "Die Team-ID fehlt.");
    required(modelId, "Die Modell-ID fehlt.");
    const model = await this.catalog.findAvailableFor(teamId, modelId);
    if (model === null) throw new Error("Das Modell ist nicht verfügbar.");
    return model;
  }
}

function resultFor(
  model: ModelCatalogEntry,
  runtimeOutputs: Awaited<ReturnType<RunModelInference["execute"]>>,
): ModelInferenceResult {
  const definitions = new Map(model.contract.outputs.map((output) => [output.name, output]));
  return {
    modelId: model.id,
    outputs: runtimeOutputs.map(({tensor, transformationValues}) => {
      const output = definitions.get(tensor.name)!;
      return {
        ...tensor,
        semantic: output.semantic,
        workflowOutput: output.workflowOutput,
        value: mapWorkflowOutput(output.workflowOutput.mapping, new Map(
          Object.entries(transformationValues),
        )),
      };
    }),
  };
}

function required(value: string, message: string): void {
  if (value.trim().length === 0) throw new Error(message);
}
