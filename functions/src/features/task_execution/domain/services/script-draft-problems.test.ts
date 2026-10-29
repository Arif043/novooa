import assert from "node:assert/strict";
import test from "node:test";
import {scriptDraftProblems} from "./script-draft-problems.js";

test("accepts a draft whose announced outputs are set in the script", () => {
  const problems = scriptDraftProblems({
    script: "summe = sum(input)\nworkflow_output(\"summe\", \"number\", summe)",
    workflowOutputs: [{name: "summe", type: "number"}],
  });

  assert.deepEqual(problems, []);
});

test("reports an empty script", () => {
  assert.deepEqual(scriptDraftProblems({script: "  ", workflowOutputs: []}), ["Das Script ist leer."]);
});

test("reports invalid, duplicate, untyped and undeclared outputs", () => {
  const problems = scriptDraftProblems({
    script: "workflow_output('a', 'string', 'x')",
    workflowOutputs: [
      {name: "value", type: "string"},
      {name: "a", type: "string"},
      {name: "a", type: "text"},
    ],
  });

  assert.equal(problems.some((problem) => problem.includes("„value“ ist ungültig")), true);
  assert.equal(problems.some((problem) => problem.includes("doppelt")), true);
  assert.equal(problems.some((problem) => problem.includes("„text“")), true);
  assert.equal(problems.some((problem) => problem.includes("„value“ ist angekündigt")), true);
});

test("reports {{…}} templates in the code, which are not replaced", () => {
  const problems = scriptDraftProblems({
    script: "betreff = \"{{mail.betreff}}\"\nworkflow_output(\"b\", \"string\", betreff)",
    workflowOutputs: [{name: "b", type: "string"}],
  });

  assert.deepEqual(problems, ["Das Script enthält {{…}}; Werte liest ein Script nur mit workflow_input(\"name\")."]);
});
