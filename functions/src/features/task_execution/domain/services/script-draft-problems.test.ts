import assert from "node:assert/strict";
import test from "node:test";
import {scriptDraftProblems} from "./script-draft-problems.js";

test("accepts a draft whose announced outputs are set in the script", () => {
  const problems = scriptDraftProblems({
    script: "summe = sum(input)\nworkflow_output(\"summe\", \"number\", summe)",
    workflowOutputs: [{name: "summe", typ: "number"}],
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
      {name: "value", typ: "string"},
      {name: "a", typ: "string"},
      {name: "a", typ: "text"},
    ],
  });

  assert.equal(problems.some((problem) => problem.includes("„value“ ist ungültig")), true);
  assert.equal(problems.some((problem) => problem.includes("doppelt")), true);
  assert.equal(problems.some((problem) => problem.includes("„text“")), true);
  assert.equal(problems.some((problem) => problem.includes("„value“ ist angekündigt")), true);
});
