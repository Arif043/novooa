import assert from "node:assert/strict";
import test from "node:test";
import {type ModelContract} from "../domain/entities/model-contract.js";
import {cloudModelContractCapabilityValidator} from "./model-contract-capabilities.js";

test("accepts the registered image transformations", () => {
  cloudModelContractCapabilityValidator().validate(contract("image", ["image.decode", "image.crop", "image.perspectiveCrop", "image.resize"]));
});

test("rejects an unsupported input source before publication", () => {
  assert.throws(() => cloudModelContractCapabilityValidator().validate(contract("text", [])), /text-Eingänge/);
});

test("delegates output transformation support to the Python runtime", () => {
  const value = contract("tensor", []);
  const changed: ModelContract = {
    ...value,
    outputs: [{
      ...value.outputs[0]!,
      transformations: [{type: "custom.output", parameters: {}}],
    }],
  };
  cloudModelContractCapabilityValidator().validate(changed);
});

test("accepts a configured generic top-k output transformation", () => {
  const value = contract("tensor", []);
  const changed: ModelContract = {
    ...value,
    outputs: [{
      ...value.outputs[0]!,
      shape: [3],
      transformations: [{
        type: "tensor.topK",
        result: "topValues",
        parameters: {
          parameter: {name: "k", default: 3, minimum: 1, maximum: 3},
        },
      }],
      workflowOutput: {
        name: "topValues",
        type: "json",
        mapping: "$topValues",
      },
    }],
  };
  cloudModelContractCapabilityValidator().validate(changed);
});

function contract(
  source: "image" | "tensor" | "text",
  transformations: readonly string[],
): ModelContract {
  return {
    inputs: [{
      name: "input", source, dataType: "float32" as const, shape: [1],
      transformations: transformations.map((type) => ({type, parameters: {}})),
    }],
    outputs: [{
      name: "output", semantic: "test", dataType: "float32" as const, shape: [1], transformations: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"},
    }],
  };
}
