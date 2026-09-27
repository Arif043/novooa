import assert from "node:assert/strict";
import test from "node:test";
import {modelSettingBindings} from "./model-setting-bindings.js";

test("uses manifest defaults for absent model parameter values", () => {
  const values = modelSettingBindings(parameters());

  assert.deepEqual(values, {speed: 1, enabled: true, style: "neutral", mood: 4});
});

test("validates supplied model parameter values", () => {
  assert.throws(
    () => modelSettingBindings(parameters(), {speed: 3}),
    /Sprechtempo/,
  );
});

test("converts persisted radio setting text to the option value type", () => {
  const values = modelSettingBindings(parameters(), {mood: "4"});

  assert.equal(values.mood, 4);
});

function parameters() {
  return [
    {name: "speed", label: "Sprechtempo", control: {type: "slider" as const, initial: 1, minimum: 0.5, maximum: 2, step: 0.1}},
    {name: "enabled", label: "Aktiv", control: {type: "checkbox" as const, initial: true}},
    {name: "style", label: "Stil", control: {type: "radioGroup" as const, initial: "neutral", options: [{value: "neutral", label: "Neutral"}]}},
    {name: "mood", label: "Stimmung", control: {type: "radioGroup" as const, initial: 4, options: [{value: 4, label: "Neutral"}]}},
  ];
}
