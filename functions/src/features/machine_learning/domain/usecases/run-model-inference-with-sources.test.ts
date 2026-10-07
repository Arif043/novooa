import assert from "node:assert/strict";
import test from "node:test";
import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelTensor} from "../entities/model-tensor.js";
import {type ModelArtifactReader} from "../repositories/model-artifact-reader.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";
import {type ModelInputTransformer} from "../repositories/model-input-transformer.js";
import {type ModelInferenceRuntime, type ModelRuntimeOutput} from "../repositories/model-inference-runtime.js";
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
  assert.deepEqual(result.outputs[0].workflowOutput, {
    name: "value",
    type: "json",
    mapping: "$tensor",
  });
  assert.deepEqual(result.outputs[0].value, [2]);
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

test("prepares a resource-aware runtime before transforming inputs", async () => {
  const transformer = new Transformer();
  const runtime = new PreparingRuntime();
  const useCase = new RunModelInferenceWithSources(
    new Catalog(contractEntry()),
    new PrepareModelInputs(transformer),
    new RunModelInference(new ArtifactReader(), runtime),
  );

  await useCase.execute({teamId: "team-1", modelId: "classifier", inputs: sources()});

  assert.deepEqual(transformer.modelKeys, ["prepared-model", "prepared-model", "prepared-model", "prepared-model"]);
  assert.equal(runtime.preparations, 1);
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
  modelKeys: (string | undefined)[] = [];

  async transform(request: Parameters<ModelInputTransformer["transform"]>[0]) {
    this.sourceTypes.push(request.source.type);
    this.modelKeys.push(request.modelKey);
    return tensor(request.input.name, [1], [1]);
  }
}

class Runtime implements ModelInferenceRuntime {
  async execute(): Promise<readonly ModelRuntimeOutput[]> {
    const tensorOutput = tensor("scores", [1], [2]);
    return [{...tensorOutput, tensor: tensorOutput, transformationValues: {tensor: [2]}}];
  }
}

class PreparingRuntime extends Runtime {
  preparations = 0;

  async prepareInputs(): Promise<string> {
    this.preparations += 1;
    return "prepared-model";
  }
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
    transformations: [],
  }));
  return {
    id: "classifier", title: "Klassifikation", description: "Testmodell", task: "image-classification", languages: [], tags: ["test"],
    scope: {type: "system"}, runtime: "onnx",
    artifactReference: {artifactId: "artifact", versionId: "1", format: "onnx", contentType: "application/onnx", sizeBytes: 1, sha256: "0000000000000000000000000000000000000000000000000000000000000000"},
    contract: {inputs, outputs: [{name: "scores", dataType: "uint8", shape: [1], semantic: "classification.scores", transformations: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"}}]},
  };
}

function sources() {
  return [
    {name: "input-0", type: "text" as const, value: "Hallo"},
    {name: "input-1", type: "number" as const, value: 4},
    {name: "input-2", type: "boolean" as const, value: true},
    {name: "input-3", type: "json" as const, value: {priority: "high"}},
  ];
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
        transformations: [],
      }],
    },
  };
}
