import assert from "node:assert/strict";
import test from "node:test";
import {type ModelOutput} from "../entities/model-contract.js";
import {type ModelTensor} from "../entities/model-tensor.js";
import {ModelOutputPostprocessor} from "./model-output-postprocessor.js";
import {ModelOutputTransformationRegistry} from "./model-output-transformation-registry.js";
import {type ModelOutputTransformationStrategy} from "./model-output-transformation-strategy.js";

test("accepts an added transformation without changing the postprocessor", () => {
  const postprocessor = new ModelOutputPostprocessor(
    new ModelOutputTransformationRegistry([constantStrategy]),
  );

  const processed = postprocessor.process(output(), tensor(), []);

  assert.equal(processed.value, "fertig");
});

const constantStrategy: ModelOutputTransformationStrategy = {
  type: "test.constant",
  validate: () => undefined,
  transform: () => "fertig",
};

function output(): ModelOutput {
  return {
    name: "output",
    semantic: "test",
    dataType: "float32",
    shape: [1],
    transformations: [{type: "test.constant", result: "constant", parameters: {}}],
    workflowOutput: {name: "value", type: "string", mapping: "$constant"},
  };
}

function tensor(): ModelTensor {
  return {
    name: "output",
    dataType: "float32",
    shape: [1],
    bytes: new Uint8Array(new Float32Array([1]).buffer),
  };
}
