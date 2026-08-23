import assert from "node:assert/strict";
import test from "node:test";
import {type ModelContract} from "../domain/entities/model-contract.js";
import {cloudModelContractCapabilityValidator} from "./model-contract-capabilities.js";

test("accepts the registered image transformations", () => {
  cloudModelContractCapabilityValidator().validate(contract("image", ["image.decode", "image.resize"]));
});

test("rejects an unsupported input source before publication", () => {
  assert.throws(() => cloudModelContractCapabilityValidator().validate(contract("text", [])), /text-Eingänge/);
});

test("rejects output transformations before publication", () => {
  const value = contract("tensor", []);
  const changed: ModelContract = {
    ...value,
    outputs: [{...value.outputs[0]!, postprocessing: [{type: "scores.topK", parameters: {count: 3}}]}],
  };
  assert.throws(() => cloudModelContractCapabilityValidator().validate(changed), /Ausgangstransformationen/);
});

function contract(
  source: "image" | "tensor" | "text",
  transformations: readonly string[],
): ModelContract {
  return {
    inputs: [{
      name: "input", source, dataType: "float32" as const, shape: [1],
      preprocessing: transformations.map((type) => ({type, parameters: {}})),
    }],
    outputs: [{
      name: "output", semantic: "test", dataType: "float32" as const, shape: [1], postprocessing: [],
    }],
  };
}
