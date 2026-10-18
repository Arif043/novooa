import assert from "node:assert/strict";
import test from "node:test";
import {modelInferenceNodeExecutor} from "./model-inference-node-executor.js";
import {succeeded} from "./node-executor-test-support.js";

test("maps the manifest-defined workflow output", async () => {
  const result = succeeded(await modelInferenceNodeExecutor.execute({
      id: "infer", primitive: "modelInference",
      config: {
        primitive: "modelInference",
        modelId: "classifier",
        inputMappings: [
          {
            modelInputName: "text_input", workflowMapping: "{{text.value}}",
            sourceType: "text", dataType: "uint8", shape: [1],
          },
          {
            modelInputName: "vector", workflowMapping: "{{previous.value.outputs.0}}",
            sourceType: "tensor", dataType: "float32", shape: [2],
          },
        ],
      },
  } as never, runContext() as never));

  assert.deepEqual(result.outputs.scores, {type: "json", value: [1, 2]});
});

function runContext() {
  return {
    teamId: "team-1",
    templateExpressionResolver: {
      resolveValue: (mapping: string) => mapping === "{{text.value}}" ? "Hallo" : {
          name: "y", dataType: "float32", shape: [2],
          dataBase64: "AACAPwAAAEA=",
        },
    },
    modelInference: {
      async execute(request: {inputs: readonly {name: string; type: string}[]}) {
        assert.deepEqual(request.inputs.map((input) => input.type), ["text", "tensor"]);
        assert.deepEqual(request.inputs.map((input) => input.name), ["text_input", "vector"]);
        return {
          modelId: "classifier",
          outputs: [{
            name: "scores", semantic: "classification.scores", workflowOutput: {name: "scores", type: "json" as const, mapping: "$tensor"}, dataType: "uint8" as const,
            shape: [2], bytes: Uint8Array.from([1, 2]),
            value: [1, 2],
          }],
        };
      },
    },
  };
}
