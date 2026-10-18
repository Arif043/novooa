import assert from "node:assert/strict";
import test from "node:test";
import {createPythonScriptExecutor} from "./python-script-executor.js";

test("liest typisierte Werte per workflow_input und sammelt workflow_output", async () => {
  const result = (await createPythonScriptExecutor().execute({
    script: [
      "summe = workflow_input(\"rechnung\")[\"summe\"]",
      "print(summe)",
      "workflow_output(\"jahr\", \"number\", workflow_input(\"faellig\").year)",
      "workflow_output(\"betreff\", \"string\", workflow_input(\"betreff\"))",
      "workflow_output(\"brutto\", \"number\", summe * 2)",
    ].join("\n"),
    inputs: {
      rechnung: {type: "json", value: {summe: 21}},
      faellig: {type: "datetime", value: "2026-10-18T09:30:00"},
      betreff: {type: "string", value: "Er sagte \"Hallo\""},
    },
  }))._unsafeUnwrap();

  assert.deepEqual(result.workflowOutputs, [
    {name: "jahr", type: "number", value: 2026},
    {name: "betreff", type: "string", value: "Er sagte \"Hallo\""},
    {name: "brutto", type: "number", value: 42},
  ]);
  assert.equal(result.printed, "21\n");
});

test("ein unbekannter Wert bricht mit verständlicher Meldung ab", async () => {
  const failure = (await createPythonScriptExecutor().execute({
    script: "x = workflow_input(\"fehlt\")", inputs: {},
  }))._unsafeUnwrapErr();

  assert.equal(failure.code, "scriptFailed");
  assert.match(failure.message, /workflow_input\("fehlt"\): Es gibt keinen Wert/);
});
