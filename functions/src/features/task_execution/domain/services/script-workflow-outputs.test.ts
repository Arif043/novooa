import assert from "node:assert/strict";
import test from "node:test";
import {workflowOutputsFrom} from "./script-workflow-outputs.js";

test("turns script outputs into flat typed workflow values", () => {
  const outputs = workflowOutputsFrom([
    {name: "kunde", type: "string", value: "Müller"},
    {name: "summe", type: "number", value: 42.5},
    {name: "bezahlt", type: "boolean", value: false},
    {name: "faellig", type: "datetime", value: "2026-10-01T12:30:00.123456"},
    {name: "rechnung", type: "json", value: {nr: "R-1"}},
    {name: "leer", type: "json", value: null},
  ])._unsafeUnwrap();

  assert.deepEqual(outputs, {
    kunde: {type: "string", value: "Müller"},
    summe: {type: "number", value: 42.5},
    bezahlt: {type: "boolean", value: false},
    faellig: {type: "datetime", value: "2026-10-01T12:30:00.123456"},
    rechnung: {type: "json", value: {nr: "R-1"}},
    leer: {type: "json", value: null},
  });
});

test("values that do not match their type are failures", () => {
  for (const [type, value] of [
    ["string", 1], ["number", "42"], ["number", Number.NaN], ["boolean", "true"], ["datetime", "morgen"], ["json", undefined],
  ] as const) {
    const failure = workflowOutputsFrom([{name: "feld", type, value}])._unsafeUnwrapErr();
    assert.deepEqual(failure.details, {reason: "wrongValueType", type, name: "feld"}, `${type} ${String(value)}`);
  }
});

test("unknown types, invalid, reserved and duplicate names are failures", () => {
  for (const raw of [
    [{name: "feld", type: "datum", value: "2026-10-01"}],
    [{name: "2fach", type: "number", value: 2}],
    [{name: "mit punkt.", type: "number", value: 2}],
    [{name: "value", type: "number", value: 2}],
    [{name: "summe", type: "number", value: 1}, {name: "summe", type: "number", value: 2}],
    ["kein Objekt"],
  ]) {
    assert.equal(workflowOutputsFrom(raw)._unsafeUnwrapErr().code, "scriptOutputInvalid", JSON.stringify(raw));
  }
});

test("accepts names with umlauts like Python identifiers", () => {
  assert.deepEqual(Object.keys(workflowOutputsFrom([{name: "fällig_am", type: "string", value: "x"}])._unsafeUnwrap()), ["fällig_am"]);
});
