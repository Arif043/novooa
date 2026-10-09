import assert from "node:assert/strict";
import test from "node:test";
import {type ModelContract} from "../domain/entities/model-contract.js";
import {legacyOutputParameterSettingName as legacySettingName} from "../domain/entities/model-setting.js";
import {withLegacyOutputParametersAsSettings} from "./legacy-output-parameter-settings.js";

test("turns an old output parameter description into a slider setting bound by name", () => {
  const contract = withLegacyOutputParametersAsSettings(contractWith({
    parameter: {name: "k", label: "Anzahl Treffer", default: 3, minimum: 1, maximum: 10},
  }));

  assert.deepEqual(contract.outputs[0]?.transformations[0]?.parameters, {k: "$scores_k"});
  assert.deepEqual(contract.settings, [{
    name: "scores_k", label: "Anzahl Treffer",
    control: {type: "slider", initial: 3, minimum: 1, maximum: 10, step: 1},
  }]);
});

test("keeps existing settings and adds the converted one", () => {
  const existing = {name: "schwelle", label: "Schwelle", control: {type: "checkbox" as const, initial: true}};
  const contract = withLegacyOutputParametersAsSettings({
    ...contractWith({parameter: {name: "k", default: 2, minimum: 1, maximum: 5}}),
    settings: [existing],
  });

  assert.deepEqual(contract.settings?.map((setting) => setting.name), ["schwelle", "scores_k"]);
  assert.equal(contract.settings?.[1]?.label, "k");
});

test("leaves contracts without old descriptions unchanged", () => {
  const contract = contractWith({k: 2});

  assert.equal(withLegacyOutputParametersAsSettings(contract), contract);
});

test("builds setting names that work as bindings", () => {
  assert.equal(legacySettingName("logits-out", "top k"), "logits_out_top_k");
  assert.equal(legacySettingName("0scores", "k"), "_0scores_k");
});

function contractWith(parameters: Record<string, unknown>): ModelContract {
  return {
    inputs: [{name: "image", source: "image", dataType: "float32", shape: [1], transformations: []}],
    outputs: [{
      name: "scores", semantic: "test.scores", dataType: "float32", shape: [1],
      transformations: [{type: "tensor.topK", parameters: parameters as never}],
      workflowOutput: {name: "scores", type: "json", mapping: "$tensor"},
    }],
    settings: [],
  };
}
