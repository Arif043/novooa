import assert from "node:assert/strict";
import test from "node:test";
import {withLegacyOutputParametersAsSettings} from "./legacy-model-output-parameters.js";
import {workflowNodeSchema} from "./task-definition.js";

test("reads stored output parameters of a model node as settings", () => {
  const node = workflowNodeSchema.parse({
    id: "modell", primitive: "modelInference", title: "Modell",
    config: {
      primitive: "modelInference", modelId: "squeezenet", inputMappings: [],
      outputParameters: [{outputName: "scores", name: "k", value: 5}],
    },
  });

  assert.deepEqual(node.config, {
    primitive: "modelInference", modelId: "squeezenet", inputMappings: [],
    settings: [{name: "scores_k", valueTemplate: "5"}],
  });
});

test("keeps an existing setting of the same name", () => {
  const config = withLegacyOutputParametersAsSettings({
    primitive: "speechToText",
    settings: [{name: "scores_k", valueTemplate: "2"}],
    outputParameters: [{outputName: "scores", name: "k", value: 9}],
  });

  assert.deepEqual(config, {primitive: "speechToText", settings: [{name: "scores_k", valueTemplate: "2"}]});
});

test("ignores other node types and incomplete entries", () => {
  const prompt = {primitive: "prompt", outputParameters: [{outputName: "a", name: "b", value: 1}]};

  assert.equal(withLegacyOutputParametersAsSettings(prompt), prompt);
  assert.deepEqual(
    withLegacyOutputParametersAsSettings({primitive: "modelInference", outputParameters: [{name: "k", value: 1}]}),
    {primitive: "modelInference", settings: []},
  );
});
