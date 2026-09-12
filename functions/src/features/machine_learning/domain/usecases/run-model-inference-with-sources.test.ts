import assert from "node:assert/strict";
import test from "node:test";
import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelTensor} from "../entities/model-tensor.js";
import {type ModelArtifactReader} from "../repositories/model-artifact-reader.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";
import {type ModelInputTransformer} from "../repositories/model-input-transformer.js";
import {type ModelInferenceRuntime} from "../repositories/model-inference-runtime.js";
import {PrepareModelInputs} from "./prepare-model-inputs.js";
import {RunModelInference} from "./run-model-inference.js";
import {RunModelInferenceWithSources} from "./run-model-inference-with-sources.js";

test("binds named sources according to the model manifest", async () => {
  const transformer = new Transformer();
  const useCase = useCaseFor(contractEntry(), transformer);
  const result = await useCase.execute({
    teamId: "team-1",
    modelId: "classifier",
    inputs: [
      {name: "input-2", type: "boolean", value: true},
      {name: "input-0", type: "text", value: "Hallo"},
      {name: "input-3", type: "json", value: {priority: "high"}},
      {name: "input-1", type: "number", value: 4},
    ],
  });

  assert.deepEqual(transformer.sourceTypes, ["text", "number", "boolean", "json"]);
  assert.equal(result.outputs[0].semantic, "classification.scores");
});

test("rejects a workflow value that conflicts with the model contract", async () => {
  const useCase = useCaseFor(textEntry(), new Transformer());

  await assert.rejects(
    () => useCase.execute({
      teamId: "team-1",
      modelId: "classifier",
      inputs: [{name: "text", type: "number", value: 4}],
    }),
    /falschen Typ/,
  );
});

function useCaseFor(
  entry: ModelCatalogEntry,
  transformer: ModelInputTransformer,
): RunModelInferenceWithSources {
  return new RunModelInferenceWithSources(
    new Catalog(entry),
    new PrepareModelInputs(transformer),
    new RunModelInference(new ArtifactReader(), new Runtime()),
  );
}

class Catalog implements ModelCatalog {
  constructor(private readonly model: ModelCatalogEntry) {}
  async save(): Promise<void> {}
  async listAvailableFor(): Promise<readonly ModelCatalogEntry[]> { return [this.model]; }
  async findAvailableFor(): Promise<ModelCatalogEntry> { return this.model; }
}

class ArtifactReader implements ModelArtifactReader {
  async read(): Promise<Uint8Array> { return Uint8Array.from([1]); }
}

class Transformer implements ModelInputTransformer {
  sourceTypes: string[] = [];

  async transform(request: Parameters<ModelInputTransformer["transform"]>[0]) {
    this.sourceTypes.push(request.source.type);
    return tensor(request.input.name, [1], [1]);
  }
}

class Runtime implements ModelInferenceRuntime {
  async execute(): Promise<readonly ModelTensor[]> { return [tensor("scores", [1], [2])]; }
}

function tensor(name: string, shape: readonly number[], values: readonly number[]): ModelTensor {
  return {name, dataType: "uint8", shape, bytes: Uint8Array.from(values)};
}

function contractEntry(): ModelCatalogEntry {
  const inputs = ["text", "number", "boolean", "json"].map((source, index) => ({
    name: `input-${index}`,
    source: source as "text" | "number" | "boolean" | "json",
    dataType: "uint8" as const,
    shape: [1],
    preprocessing: [],
  }));
  return {
    id: "classifier", title: "Klassifikation", description: "Testmodell", tags: ["test"],
    scope: {type: "system"}, runtime: "onnx",
    artifactReference: {artifactId: "artifact", versionId: "1", format: "onnx", contentType: "application/onnx", sizeBytes: 1, sha256: "0000000000000000000000000000000000000000000000000000000000000000"},
    contract: {inputs, outputs: [{name: "scores", dataType: "uint8", shape: [1], semantic: "classification.scores", postprocessing: []}]},
  };
}

function textEntry(): ModelCatalogEntry {
  const entry = contractEntry();
  return {
    ...entry,
    contract: {
      ...entry.contract,
      inputs: [{
        name: "text",
        source: "text",
        dataType: "uint8",
        shape: [1],
        preprocessing: [],
      }],
    },
  };
}
