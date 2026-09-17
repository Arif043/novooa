import assert from "node:assert/strict";
import test from "node:test";
import {type WorkflowExecutionScope} from "../../../domain/executors/node-executor.js";
import {
  resolveVariableTemplateValue,
  resolveVariableTemplates,
  variableTemplateContextFor,
} from "./variable-template.js";

test("resolves the current iteration value without serializing it", () => {
  const context = contextFor({iteration: {index: 1, value: {bounds: [1, 2]}}});

  assert.deepEqual(
    resolveVariableTemplateValue("{{iteration.value.bounds}}", context),
    [1, 2],
  );
  assert.equal(resolveVariableTemplates("Nr. {{iteration.index}}", context), "Nr. 1");
});

test("resolves outer graph values from the global scope", () => {
  const context = contextFor({
    global: {
      invoice: {value: {number: "R-42"}},
      input: {customer: "Meyer GmbH"},
    },
  });

  assert.equal(resolveVariableTemplateValue("{{global.invoice.value.number}}", context), "R-42");
  assert.equal(resolveVariableTemplateValue("{{invoice.value.number}}", context), "R-42");
  assert.equal(resolveVariableTemplateValue("{{global.input.customer}}", context), "Meyer GmbH");
});

function contextFor(scope: WorkflowExecutionScope) {
  return variableTemplateContextFor(
    {nodes: [], edges: []},
    new Map(),
    {},
    scope,
  );
}
