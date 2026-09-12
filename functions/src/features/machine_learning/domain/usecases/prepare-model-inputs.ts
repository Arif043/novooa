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
  if (sourcesByName.size !== sources.length || sourcesByName.size !== inputs.length) {
    throw new Error("Die Eingabezuordnungen stimmen nicht mit dem Manifest überein.");
  }
  inputs.forEach((input) => validateSourceFor(input, sourcesByName));
  return sourcesByName;
}

function validateSourceFor(
  input: ModelInput,
  sources: ReadonlyMap<string, ModelInputSource>,
): void {
  const source = sources.get(input.name);
  if (!source) throw new Error(`Die Quelle für ${input.name} fehlt.`);
  validateModelInputSource(source, input);
}
