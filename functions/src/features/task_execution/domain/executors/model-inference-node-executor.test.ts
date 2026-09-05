import assert from "node:assert/strict";
import test from "node:test";
import {modelInferenceNodeExecutor} from "./model-inference-node-executor.js";

test("adapts predecessor values and serializes model tensor outputs", async () => {
  const result = await modelInferenceNodeExecutor.execute({
    node: {
      id: "infer", primitive: "modelInference",
      config: {primitive: "modelInference", modelId: "classifier"},
    },
    parentOutputs: [
      {
        nodeId: "text", outputName: "value", value: {type: "string", value: "Hallo"},
      },
      {
        nodeId: "media", outputName: "value", value: {
          type: "media", value: {
            fileId: "image", versionId: "version", displayName: "bild.png",
            contentType: "image/png", sizeBytes: 2,
          },
        },
      },
    ],
  } as never, runContext() as never);

  assert.equal(result.outputs.modelId.value, "classifier");
  assert.deepEqual(result.outputs.value.value, {
    modelId: "classifier",
    outputs: [{
      name: "scores", semantic: "classification.scores", dataType: "uint8",
      shape: [2], dataBase64: "AQI=",
    }],
  });
});

function runContext() {
  return {
    teamId: "team-1",
    fileContentReader: {
      async readTeamFileContent() {
        return {
          content: Uint8Array.from([137, 80]), displayName: "bild.png",
          contentType: "image/png", sizeBytes: 2,
        };
      },
    },
    modelInference: {
      async execute(request: {inputs: readonly {type: string}[]}) {
        assert.deepEqual(request.inputs.map((input) => input.type), ["text", "image"]);
        return {
          modelId: "classifier",
          outputs: [{
            name: "scores", semantic: "classification.scores", dataType: "uint8" as const,
            shape: [2], bytes: Uint8Array.from([1, 2]),
          }],
        };
      },
    },
  };
}
