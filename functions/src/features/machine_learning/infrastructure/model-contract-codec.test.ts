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
      transformations: [],
    })),
    outputs: [{
      name: "output",
      dataType: "float32",
      shape: [1],
      semantic: "test.output",
      transformations: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"},
    }],
  });

  assert.deepEqual(contract.inputs.map((input) => input.source), [
    "image", "file", "text", "datetime", "number", "boolean", "json", "tensor",
  ]);
});

test("requires a declarative workflow output mapping", () => {
  assert.throws(
    () => modelContractFromUnknown({
      inputs: [{name: "input", source: "tensor", dataType: "float32", shape: [1], transformations: []}],
      outputs: [{
        name: "output", dataType: "float32", shape: [1], semantic: "test.output",
        transformations: [],
      }],
    }),
    /Workflow-Ausgabe/,
  );
});

test("decodes input bindings and configurable model parameters", () => {
  const contract = modelContractFromUnknown({
    inputs: [
      {name: "text", source: "text", dataType: "int64", shape: [1], transformations: []},
      {name: "length", source: "text", binding: {type: "derived", inputName: "text"}, dataType: "int64", shape: [1], transformations: []},
      {name: "scale", source: "text", binding: {type: "generated", value: ""}, dataType: "float32", shape: [1], transformations: []},
    ],
    settings: [
      {name: "speed", label: "Sprechtempo", control: {type: "slider", initial: 1, minimum: 0.5, maximum: 2, step: 0.1}},
      {name: "style", label: "Stil", control: {type: "radioGroup", initial: "neutral", options: [{value: "neutral", label: "Neutral"}]}},
    ],
    outputs: [{name: "output", dataType: "float32", shape: [1], semantic: "test.output", transformations: [], workflowOutput: {name: "value", type: "json", mapping: "$tensor"}}],
  });

  assert.deepEqual(contract.inputs[1]?.binding, {type: "derived", inputName: "text"});
  assert.equal(contract.settings?.[0]?.control.type, "slider");
});
