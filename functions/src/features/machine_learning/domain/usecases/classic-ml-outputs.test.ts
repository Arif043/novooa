import assert from "node:assert/strict";
import test from "node:test";
import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {validateModelContract} from "../entities/model-contract.js";
import {type ModelTensor, validateModelTensor} from "../entities/model-tensor.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";
import {type ModelInferenceRuntime, type ModelRuntimeOutput} from "../repositories/model-inference-runtime.js";
import {mapWorkflowOutput} from "../services/workflow-output-mapper.js";
import {PrepareModelInputs} from "./prepare-model-inputs.js";
import {RunModelInference} from "./run-model-inference.js";
import {RunModelInferenceWithSources} from "./run-model-inference-with-sources.js";

test("string tensors carry one JSON text per element", () => {
  validateModelTensor(stringTensor("label", [2], ["ja", "Grüße"]));

  assert.throws(() => validateModelTensor(stringTensor("label", [3], ["ja"])), /Byte-Länge von Tensor label/);
  assert.throws(() => validateModelTensor({...stringTensor("label", [1], ["ja"]), bytes: Uint8Array.from([123])}), /Byte-Länge/);
  assert.throws(() => validateModelTensor({...stringTensor("label", [1], ["x"]), bytes: utf8("[1]")}), /Byte-Länge/);
});

test("float16 tensors use two bytes per element", () => {
  validateModelTensor({name: "x", dataType: "float16", shape: [3], bytes: new Uint8Array(6)});

  assert.throws(() => validateModelTensor({name: "x", dataType: "float16", shape: [3], bytes: new Uint8Array(12)}), /Byte-Länge/);
});

test("a mapping reads the values of other outputs and looks labels up by reference", () => {
  const values = new Map<string, unknown>([
    ["tensor", [[0.2, 0.8]]],
    ["best", [1]],
    ["classes", ["nein", "ja"]],
    ["outputs", {output_label: {tensor: ["ja"]}}],
  ]);

  const mapped = mapWorkflowOutput(
    {label: "$outputs.output_label.tensor.0", predicted: {$lookup: {values: "$classes", key: "$best.0"}}},
    values as never,
  );

  assert.deepEqual(mapped, {label: "ja", predicted: "ja"});
});

test("`outputs` is reserved as a transformation result name", () => {
  const contract = classifier().contract;
  const output = contract.outputs[1]!;
  const reserved = {...output, transformations: [{type: "tensor.softmax", parameters: {}, result: "outputs"}]};

  assert.throws(() => validateModelContract({...contract, outputs: [contract.outputs[0]!, reserved]}), /outputs ist reserviert/);
});

test("combines label and probability of a scikit-learn classifier into one workflow value", async () => {
  const useCase = new RunModelInferenceWithSources(
    new Catalog(classifier()),
    new PrepareModelInputs({transform: async ({input}) => floatTensor(input.name, [1, 2], [3, 3])}),
    new RunModelInference(new Runtime()),
  );

  const result = await useCase.execute({teamId: "team-1", modelId: "klassifikator", inputs: [{name: "X", type: "json", value: [[3, 3]]}]});

  assert.equal(result.outputs[0]?.value, "ja");
  assert.deepEqual(result.outputs[1]?.value, {label: "ja", score: 0.95});
});

class Runtime implements ModelInferenceRuntime {
  async execute(): Promise<readonly ModelRuntimeOutput[]> {
    const label = stringTensor("output_label", [1], ["ja"]);
    const probability = floatTensor("output_probability", [1, 2], [0.95, 0.05]);
    return [
      {...label, tensor: label, transformationValues: {tensor: ["ja"]}},
      {...probability, tensor: probability, transformationValues: {tensor: [[0.95, 0.05]], best: [0.95], classes: ["ja", "nein"]}},
    ];
  }
}

class Catalog implements ModelCatalog {
  constructor(private readonly model: ModelCatalogEntry) {}
  async save(): Promise<void> {}
  async listAvailableFor(): Promise<readonly ModelCatalogEntry[]> { return [this.model]; }
  async findAvailableFor(): Promise<ModelCatalogEntry> { return this.model; }
}

function classifier(): ModelCatalogEntry {
  return {
    id: "klassifikator", title: "Klassifikator", description: "sklearn", task: "tabular-classification", languages: [], tags: [],
    scope: {type: "system"}, runtime: "onnx",
    artifactReference: {artifactId: "a", versionId: "1", format: "onnx", contentType: "application/onnx", sizeBytes: 1, sha256: "0".repeat(64)},
    contract: {
      inputs: [{name: "X", source: "json", dataType: "float32", shape: ["dynamic", 2], transformations: [{type: "json.toTensor", parameters: {}}]}],
      outputs: [
        {name: "output_label", dataType: "string", shape: ["dynamic"], semantic: "classification.label", transformations: [],
          workflowOutput: {name: "klasse", type: "string", mapping: "$tensor.0"}},
        {name: "output_probability", dataType: "float32", shape: ["dynamic", "dynamic"], semantic: "classification.scores",
          transformations: [{type: "tensor.reduce", parameters: {operation: "max"}, result: "best"}],
          workflowOutput: {name: "ergebnis", type: "json", mapping: {label: "$outputs.output_label.tensor.0", score: "$best.0"}}},
      ],
    },
  };
}

function stringTensor(name: string, shape: number[], values: string[]): ModelTensor {
  return {name, dataType: "string", shape, bytes: utf8(JSON.stringify(values))};
}

function floatTensor(name: string, shape: number[], values: number[]): ModelTensor {
  return {name, dataType: "float32", shape, bytes: new Uint8Array(Float32Array.from(values).buffer)};
}

function utf8(text: string): Uint8Array {
  return new TextEncoder().encode(text);
}
