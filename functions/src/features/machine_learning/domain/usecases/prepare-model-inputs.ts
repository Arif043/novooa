import {type ModelContract, type ModelInput} from "../entities/model-contract.js";
import {
  type ModelInputSource,
  validateModelInputSource,
} from "../entities/model-input-source.js";
import {type ModelTensor, validateTensorsForContract} from "../entities/model-tensor.js";
import {type ModelInputTransformer} from "../repositories/model-input-transformer.js";

export class PrepareModelInputs {
  constructor(private readonly transformer: ModelInputTransformer) {}

  async execute(
    contract: ModelContract,
    sources: readonly ModelInputSource[],
  ): Promise<readonly ModelTensor[]> {
    const sourcesByName = sourceMapFor(sources, contract.inputs);
    const tensors = await Promise.all(contract.inputs.map((input) => {
      const source = sourcesByName.get(input.name)!;
      return this.transformer.transform({input, source});
    }));
    validateTensorsForContract(tensors, contract.inputs, "Eingabe");
    return tensors;
  }
}

function sourceMapFor(
  sources: readonly ModelInputSource[],
  inputs: readonly ModelInput[],
): ReadonlyMap<string, ModelInputSource> {
  const sourcesByName = new Map(sources.map((source) => [source.name, source]));
  const workflowInputs = inputs.filter((input) => (input.binding?.type ?? "workflow") === "workflow");
  if (sourcesByName.size !== sources.length) {
    throw new Error("Die Eingabezuordnungen stimmen nicht mit dem Manifest überein.");
  }
  const workflowSources = new Map(workflowInputs.map((input) => [
    input.name,
    workflowSource(input, sourcesByName),
  ]));
  return resolvedSources(inputs, workflowSources);
}

function resolvedSources(
  inputs: readonly ModelInput[],
  workflowSources: ReadonlyMap<string, ModelInputSource>,
): ReadonlyMap<string, ModelInputSource> {
  const resolved = new Map(workflowSources);
  for (const input of inputs) {
    const binding = input.binding ?? {type: "workflow"};
    const source = binding.type === "workflow"
      ? workflowSource(input, workflowSources)
      : binding.type === "derived"
        ? derivedSource(input, binding.inputName, resolved)
        : generatedSource(input, binding.value);
    validateModelInputSource(source, input);
    resolved.set(input.name, source);
  }
  return resolved;
}

function workflowSource(input: ModelInput, sources: ReadonlyMap<string, ModelInputSource>): ModelInputSource {
  const source = sources.get(input.name);
  if (source === undefined) throw new Error(`Die Quelle für ${input.name} fehlt.`);
  return source;
}

function derivedSource(
  input: ModelInput,
  inputName: string,
  sources: ReadonlyMap<string, ModelInputSource>,
): ModelInputSource {
  const source = sources.get(inputName);
  if (source === undefined) throw new Error(`Die Quelle für ${input.name} fehlt.`);
  return {...source, name: input.name};
}

function generatedSource(input: ModelInput, value: unknown): ModelInputSource {
  if (input.source === "text" || input.source === "datetime") return {name: input.name, type: input.source, value: stringValue(value)};
  if (input.source === "number" && typeof value === "number") return {name: input.name, type: "number", value};
  if (input.source === "boolean" && typeof value === "boolean") return {name: input.name, type: "boolean", value};
  if (input.source === "json") return {name: input.name, type: "json", value};
  throw new Error(`Der generierte Modelleingang ${input.name} hat keinen unterstützten Quelltyp.`);
}

function stringValue(value: unknown): string {
  if (typeof value === "string") return value;
  throw new Error("Der generierte Modelleingang benötigt Text.");
}
