import assert from "node:assert/strict";
import test from "node:test";
import {type ModelContract, validateModelContract} from "./model-contract.js";

test("validates an image classification model contract", () => {
  validateModelContract(imageClassificationContract());
});

test("rejects duplicate input tensor names", () => {
  const contract = imageClassificationContract();
  const duplicate = {...contract.inputs[0], source: "tensor" as const};

  assert.throws(() => validateModelContract({...contract, inputs: [...contract.inputs, duplicate]}));
});

test("requires a workflow output per tensor output", () => {
  const contract = imageClassificationContract();
  const output = {...contract.outputs[0]!, workflowOutput: {...contract.outputs[0]!.workflowOutput, name: ""}};

  assert.throws(
    () => validateModelContract({...contract, outputs: [output]}),
    /Workflow-Ausgabe/,
  );
});

test("rejects duplicate transformation result names", () => {
  const contract = imageClassificationContract();
  const output: ModelContract["outputs"][number] = {
    ...contract.outputs[0]!,
    postprocessing: [
      {type: "tensor.softmax", result: "scores", parameters: {axis: -1}},
      {type: "tensor.softmax", result: "scores", parameters: {axis: -1}},
    ],
  };

  assert.throws(
    () => validateModelContract({...contract, outputs: [output]}),
    /eindeutig/,
  );
});

function imageClassificationContract(): ModelContract {
  return {
    inputs: [{
      name: "image",
      source: "image",
      dataType: "float32",
      shape: ["dynamic", 3, 224, 224],
      preprocessing: [{
        type: "image.resize",
        parameters: {width: 224, height: 224, colorSpace: "rgb"},
      }],
    }],
    outputs: [{
      name: "scores",
      dataType: "float32",
      shape: ["dynamic", 1000],
      semantic: "classification.scores",
      postprocessing: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"},
    }],
  };
}
