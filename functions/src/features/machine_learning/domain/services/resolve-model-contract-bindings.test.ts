import assert from "node:assert/strict";
import test from "node:test";
import {resolveModelContractBindings} from "./resolve-model-contract-bindings.js";

test("resolves iteration bindings in input and output transformations", () => {
  const contract = resolveModelContractBindings(contractWithBindings(), {
    iteration: {index: 2, value: {bounds: [4, 8, 16, 32]}},
  });

  assert.deepEqual(contract.inputs[0].transformations[0].parameters, {
    bounds: [4, 8, 16, 32],
  });
  assert.equal(contract.outputs[0].transformations[0].parameters.index, 2);
});

test("resolves global graph bindings", () => {
  const contract = resolveModelContractBindings(contractWithGlobalBinding(), {
    global: {detector: {value: {threshold: 0.75}}},
  });

  assert.equal(contract.outputs[0].transformations[0].parameters.threshold, 0.75);
});

test("rejects an unresolved transformation binding", () => {
  assert.throws(
    () => resolveModelContractBindings(contractWithBindings(), {}),
    /\$iteration.value.bounds/,
  );
});

function contractWithBindings() {
  return {
    inputs: [{
      name: "image", source: "image" as const, dataType: "float32" as const,
      shape: [1], transformations: [{
        type: "image.crop", parameters: {bounds: "$iteration.value.bounds"},
      }],
    }],
    outputs: [{
      name: "output", semantic: "test.output", dataType: "float32" as const,
      shape: [1], transformations: [{
        type: "tensor.topK", parameters: {index: "$iteration.index"},
      }],
      workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"},
    }],
  };
}

function contractWithGlobalBinding() {
  const contract = contractWithBindings();
  return {
    ...contract,
    inputs: [],
    outputs: [{
      ...contract.outputs[0],
      transformations: [{
        type: "tensor.topK",
        parameters: {threshold: "$global.detector.value.threshold"},
      }],
    }],
  };
}
