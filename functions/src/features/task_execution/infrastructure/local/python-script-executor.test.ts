import assert from "node:assert/strict";
import test from "node:test";
import {createPythonScriptExecutor} from "./python-script-executor.js";

test("sammelt workflow_output-Aufrufe und Variablen des Scripts", async () => {
  const result = (await createPythonScriptExecutor().execute({
    script: "summe = zaehler + 1\nprint(summe)\nworkflow_output(\"summe\", \"number\", summe)",
    variables: {zaehler: 1},
  }))._unsafeUnwrap();

  assert.deepEqual(result.workflowOutputs, [{name: "summe", type: "number", value: 2}]);
  assert.deepEqual(result.variables, {zaehler: 1, summe: 2});
  assert.equal(result.printed, "2\n");
});

test("input und output gibt es im Script nicht mehr", async () => {
  const failure = (await createPythonScriptExecutor().execute({script: "x = input", variables: {}}))._unsafeUnwrapErr();

  assert.equal(failure.code, "scriptFailed");
  assert.match(failure.message, /NameError/);
});
