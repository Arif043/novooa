import assert from "node:assert/strict";
import test from "node:test";
import {type ModelOutput} from "../entities/model-contract.js";
import {type ModelTensor} from "../entities/model-tensor.js";
import {ModelOutputPostprocessor} from "./model-output-postprocessor.js";

test("maps generic top-k values into the declared workflow structure", () => {
  const processed = new ModelOutputPostprocessor().process(
    output(), tensor([1, 2, 3]), [{outputName: "scores", name: "k", value: 2}],
  );

  assert.deepEqual(processed.workflowOutput.name, "classifications");
  assert.deepEqual(processed.value, [
    {index: 2, label: "Drei", score: 0.6652409557748218},
    {index: 1, label: "Zwei", score: 0.24472847105479764},
  ]);
});

test("rejects a top-k value outside the manifest range", () => {
  assert.throws(
    () => new ModelOutputPostprocessor().process(output(), tensor([1, 2, 3]), [{outputName: "scores", name: "k", value: 4}]),
    /außerhalb des erlaubten Bereichs/,
  );
});

function output(): ModelOutput {
  return {
    name: "scores", semantic: "classification.scores", dataType: "float32", shape: [1, 3],
    postprocessing: [
      {type: "tensor.softmax", parameters: {axis: -1}},
      {type: "tensor.topK", result: "topClasses", parameters: {
        parameter: {name: "k", default: 3, minimum: 1, maximum: 3},
      }},
    ],
    workflowOutput: {
      name: "classifications",
      type: "json",
      mapping: {"$map": {from: "topClasses", item: {
        index: "$item.index",
        label: {"$lookup": {values: ["Eins", "Zwei", "Drei"], key: "$item.index"}},
        score: "$item.value",
      }}},
    },
  };
}

function tensor(values: readonly number[]): ModelTensor {
  return {name: "scores", dataType: "float32", shape: [1, 3], bytes: new Uint8Array(new Float32Array(values).buffer)};
}
