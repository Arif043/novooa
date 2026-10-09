import {type ModelTensor, validateTensorsForContract} from "../entities/model-tensor.js";
import {type ModelArtifactReader} from "../repositories/model-artifact-reader.js";
import {
  type ModelInferenceRuntime,
  type ModelInputPreparationRuntime,
  type ModelRuntimeOutput,
} from "../repositories/model-inference-runtime.js";
import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelRuntimeResource} from "../entities/model-runtime-resource.js";

export type RunModelInferenceRequest = {
  readonly model: ModelCatalogEntry;
  readonly inputs: readonly ModelTensor[];
};

export class RunModelInference {
  constructor(
    private readonly artifactReader: ModelArtifactReader,
    private readonly runtime: ModelInferenceRuntime,
  ) {}

  async execute(request: RunModelInferenceRequest): Promise<readonly ModelRuntimeOutput[]> {
    validateTensorsForContract(request.inputs, request.model.contract.inputs, "Eingabe");
    const artifact = await this.artifactReader.read(request.model.artifactReference);
    const resources = await this.resourcesFor(request.model.artifactReference);
    const outputs = await this.runtime.execute({...request, artifact, resources});
    validateTensorsForContract(outputs.map((output) => output.tensor), request.model.contract.outputs, "Ausgabe");
    return outputs;
  }

  async prepareInputs(model: ModelCatalogEntry): Promise<string | undefined> {
    if (!isPreparationRuntime(this.runtime)) return undefined;
    const artifact = await this.artifactReader.read(model.artifactReference);
    const resources = await this.resourcesFor(model.artifactReference);
    return this.runtime.prepareInputs({model, artifact, resources});
  }

  private async resourcesFor(reference: ModelCatalogEntry["artifactReference"]): Promise<readonly ModelRuntimeResource[]> {
    const resources = reference.resources ?? [];
    if (resources.length === 0) return [];
    if (this.artifactReader.readResource === undefined) throw new Error("Die Runtime kann Modellressourcen nicht lesen.");
    return Promise.all(resources.map(async (resource) => ({...resource, bytes: await this.artifactReader.readResource!(reference, resource)})));
  }
}

function isPreparationRuntime(runtime: ModelInferenceRuntime): runtime is ModelInferenceRuntime & ModelInputPreparationRuntime {
  return "prepareInputs" in runtime && typeof runtime.prepareInputs === "function";
}
