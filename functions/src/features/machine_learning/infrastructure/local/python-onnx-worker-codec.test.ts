import assert from "node:assert/strict";
import test from "node:test";
import {type PythonOnnxWorkerRequest} from "./python-onnx-worker.js";
import {
  pythonOnnxWorkerInputJson,
  pythonOnnxWorkerOutputFromJson,
} from "./python-onnx-worker-codec.js";

test("serializes binary model and tensor inputs for the Python worker", () => {
  const payload = JSON.parse(pythonOnnxWorkerInputJson(request())) as {
    modelBase64: string;
    inputs: Array<{dataBase64: string}>;
  };

  assert.deepEqual([...Buffer.from(payload.modelBase64, "base64")], [1, 2, 3, 4]);
  assert.deepEqual([...Buffer.from(payload.inputs[0].dataBase64, "base64")], [12]);
});

test("decodes typed tensors returned by the Python worker", () => {
  const tensors = pythonOnnxWorkerOutputFromJson(JSON.stringify({
    outputs: [{name: "output", dataType: "uint8", shape: [1], dataBase64: "DA==", transformationValues: {tensor: [12]}}],
  }));

  assert.equal(tensors[0].name, "output");
  assert.deepEqual([...tensors[0].bytes], [12]);
});

function request(): PythonOnnxWorkerRequest {
  return {
    artifact: Uint8Array.from([1, 2, 3, 4]),
    inputs: [{name: "input", dataType: "uint8", shape: [1], bytes: Uint8Array.from([12])}],
    outputs: [output()],
  };
}

function output() {
  return {
    name: "output", dataType: "uint8" as const, shape: [1], semantic: "test.output",
    transformations: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"},
  };
}
