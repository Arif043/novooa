import assert from "node:assert/strict";
import test from "node:test";
import {type ModelInputTransformer} from "../repositories/model-input-transformer.js";
import {PrepareModelInputs} from "./prepare-model-inputs.js";

test("transforms named sources in the order of the model contract", async () => {
  const transformer = new Transformer();
  const useCase = new PrepareModelInputs(transformer);

  const tensors = await useCase.execute(contract(), [imageSource("image")]);

  assert.deepEqual(tensors[0].shape, [1]);
  assert.deepEqual(transformer.inputNames, ["image"]);
});

test("rejects sources with a different type than the contract", async () => {
  const useCase = new PrepareModelInputs(new Transformer());

  await assert.rejects(
    () => useCase.execute(contract(), [tensorSource("image")]),
    /falschen Typ/,
  );
});

class Transformer implements ModelInputTransformer {
  inputNames: string[] = [];

  async transform(request: Parameters<ModelInputTransformer["transform"]>[0]) {
    this.inputNames.push(request.input.name);
    return {
      name: request.input.name,
      dataType: "uint8" as const,
      shape: [1],
      bytes: Uint8Array.from([1]),
    };
  }
}

function contract() {
  return {
    inputs: [{name: "image", source: "image" as const, dataType: "uint8" as const, shape: [1], transformations: []}],
    outputs: [{name: "output", dataType: "uint8" as const, shape: [1], semantic: "test.output", transformations: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"}}],
  };
}

function imageSource(name: string) {
  return {name, type: "image" as const, contentType: "image/png", bytes: Uint8Array.from([1])};
}

function tensorSource(name: string) {
  return {
    name,
    type: "tensor" as const,
    tensor: {name, dataType: "uint8" as const, shape: [1], bytes: Uint8Array.from([1])},
  };
}
