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
      postprocessing: [],
    }],
  };
}
