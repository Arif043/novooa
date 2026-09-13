import assert from "node:assert/strict";
import test from "node:test";
import {modelContractFromUnknown} from "./model-contract-codec.js";

test("decodes every supported model input source", () => {
  const contract = modelContractFromUnknown({
    inputs: [
      "image", "file", "text", "datetime", "number", "boolean", "json", "tensor",
    ].map((source, index) => ({
      name: `input-${index}`,
      source,
      dataType: "float32",
      shape: [1],
      preprocessing: [],
    })),
    outputs: [{
      name: "output",
      dataType: "float32",
      shape: [1],
      semantic: "test.output",
      postprocessing: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"},
    }],
  });

  assert.deepEqual(contract.inputs.map((input) => input.source), [
    "image", "file", "text", "datetime", "number", "boolean", "json", "tensor",
  ]);
});

test("requires a declarative workflow output mapping", () => {
  assert.throws(
    () => modelContractFromUnknown({
      inputs: [{name: "input", source: "tensor", dataType: "float32", shape: [1], preprocessing: []}],
      outputs: [{
        name: "output", dataType: "float32", shape: [1], semantic: "test.output",
        postprocessing: [],
      }],
    }),
    /Workflow-Ausgabe/,
  );
});
