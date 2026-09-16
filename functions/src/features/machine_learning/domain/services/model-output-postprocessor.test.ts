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
    transformations: [
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

test("converts a thresholded mask into generic connected regions", () => {
  const processed = new ModelOutputPostprocessor().process(
    outputWith([
      {type: "tensor.threshold", parameters: {value: 0.5}},
      {type: "mask.connectedComponents", result: "regions", parameters: {minimumPixels: 2}},
    ], "$regions"),
    tensorWithShape([1, 4, 4], [0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1]),
    [],
  );

  assert.deepEqual(processed.value, [
    {bounds: {left: 1, top: 0, width: 2, height: 2}, pixelCount: 3},
    {bounds: {left: 0, top: 2, width: 1, height: 2}, pixelCount: 2},
    {bounds: {left: 3, top: 2, width: 1, height: 2}, pixelCount: 2},
  ]);
});

test("suppresses overlapping detections without model-specific output fields", () => {
  const processed = new ModelOutputPostprocessor().process(
    outputWith([{
      type: "tensor.nonMaximumSuppression",
      result: "detections",
      parameters: {
        box: {left: 0, top: 1, right: 2, bottom: 3},
        scoreIndex: 4,
        iouThreshold: 0.5,
      },
    }], "$detections"),
    tensorWithShape([3, 5], [0, 0, 10, 10, 0.9, 1, 1, 9, 9, 0.8, 20, 20, 30, 30, 0.7]),
    [],
  );

  assert.deepEqual(processed.value, [
    {index: 0, score: 0.8999999761581421, box: {left: 0, top: 0, right: 10, bottom: 10}},
    {index: 2, score: 0.699999988079071, box: {left: 20, top: 20, right: 30, bottom: 30}},
  ]);
});

test("decodes CTC logits into declared workflow values", () => {
  const processed = new ModelOutputPostprocessor().process(
    outputWith([{
      type: "sequence.ctcGreedyDecode",
      result: "lines",
      parameters: {labels: ["", "A", "B"], blankIndex: 0},
    }], "$lines"),
    tensorWithShape([1, 5, 3], [0, 5, 0, 0, 5, 0, 5, 0, 0, 0, 0, 5, 0, 0, 5]),
    [],
  );

  assert.deepEqual((processed.value as readonly {text: string}[]).map((item) => item.text), ["AB"]);
  assert.ok(Math.abs(((processed.value as readonly {confidence: number}[])[0]?.confidence ?? 0) - 0.986703291042) < 0.000001);
});

function outputWith(
  transformations: ModelOutput["transformations"],
  mapping: ModelOutput["workflowOutput"]["mapping"],
): ModelOutput {
  return {
    name: "output",
    semantic: "test.output",
    dataType: "float32",
    shape: [1],
    transformations,
    workflowOutput: {name: "value", type: "json", mapping},
  };
}

function tensorWithShape(shape: readonly number[], values: readonly number[]): ModelTensor {
  return {
    name: "output",
    dataType: "float32",
    shape,
    bytes: new Uint8Array(new Float32Array(values).buffer),
  };
}
