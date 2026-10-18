import assert from "node:assert/strict";
import test from "node:test";
import {scriptWorkflowInputPaths} from "./script-workflow-inputs.js";

test("findet feste Pfade in Reihenfolge, ohne Doppelte und ohne Kommentare", () => {
  const script = [
    "rechnung = workflow_input(\"rechnung\")",
    "summe = workflow_input('rechnung.summe') + workflow_input(\"rechnung\")",
    "# workflow_input(\"auskommentiert\")",
    "erste = workflow_input(\"positionen.0\")",
    "name = workflow_input(variable)",
    "kaputt = workflow_input(\"1falsch\")",
  ].join("\n");

  assert.deepEqual(scriptWorkflowInputPaths(script), ["rechnung", "rechnung.summe", "positionen.0"]);
});
