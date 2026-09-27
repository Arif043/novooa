import assert from "node:assert/strict";
import test from "node:test";
import {modelSettingBindings} from "./model-setting-bindings.js";

test("uses manifest defaults for absent model parameter values", () => {
  const values = modelSettingBindings(parameters());

  assert.deepEqual(values, {speed: 1, enabled: true, style: "neutral"});
});

test("validates supplied model parameter values", () => {
  assert.throws(
    () => modelSettingBindings(parameters(), {speed: 3}),
    /Sprechtempo/,
  );
});

function parameters() {
  return [
    {name: "speed", label: "Sprechtempo", control: {type: "slider" as const, initial: 1, minimum: 0.5, maximum: 2, step: 0.1}},
    {name: "enabled", label: "Aktiv", control: {type: "checkbox" as const, initial: true}},
    {name: "style", label: "Stil", control: {type: "radioGroup" as const, initial: "neutral", options: [{value: "neutral", label: "Neutral"}]}},
  ];
}
