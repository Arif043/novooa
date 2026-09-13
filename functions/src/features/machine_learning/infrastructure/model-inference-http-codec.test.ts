import assert from "node:assert/strict";
import test from "node:test";
import {
  modelInferenceRequestFromJson,
  modelInferenceResultJson,
} from "./model-inference-http-codec.js";

test("decodes portable binary and tensor inference inputs", () => {
  const request = modelInferenceRequestFromJson({
    teamId: "team-1",
    modelId: "classifier",
    inputs: [
      {name: "image", type: "image", contentType: "image/png", dataBase64: "AQI="},
      {name: "input", type: "tensor", tensor: tensorJson("input", "AwQ=")},
    ],
  });

  const image = request.inputs[0];
  const tensor = request.inputs[1];
  assert.equal(image.type, "image");
  assert.equal(tensor.type, "tensor");
  if (image.type !== "image" || tensor.type !== "tensor") throw new Error("Ungültiger Testwert.");
  assert.deepEqual([...image.bytes], [1, 2]);
  assert.deepEqual([...tensor.tensor.bytes], [3, 4]);
});

test("rejects malformed binary input before model inference", () => {
  assert.throws(
    () => modelInferenceRequestFromJson({
      teamId: "team-1",
      modelId: "classifier",
      inputs: [{name: "image", type: "image", contentType: "image/png", dataBase64: "not base64"}],
    }),
    /Binärdaten/,
  );
});

test("encodes output tensors without exposing runtime details", () => {
  const response = modelInferenceResultJson({
    modelId: "classifier",
    outputs: [{
      name: "scores",
      semantic: "classification.scores",
      workflowOutput: {name: "classifications", type: "json" as const, mapping: "$tensor"},
      dataType: "uint8",
      shape: [2],
      bytes: Uint8Array.from([4, 5]),
      value: [
        {index: 1, label: "Klasse zwei", score: 0.7},
        {index: 0, label: "Klasse eins", score: 0.3},
      ],
    }],
  });

  assert.deepEqual(response, {
    modelId: "classifier",
    outputs: [{
      ...tensorJson("scores", "BAU="),
      semantic: "classification.scores",
      workflowOutput: {name: "classifications", type: "json" as const, mapping: "$tensor"},
      value: [
        {index: 1, label: "Klasse zwei", score: 0.7},
        {index: 0, label: "Klasse eins", score: 0.3},
      ],
    }],
  });
});

function tensorJson(name: string, dataBase64: string) {
  return {name, dataType: "uint8", shape: [2], dataBase64};
}
