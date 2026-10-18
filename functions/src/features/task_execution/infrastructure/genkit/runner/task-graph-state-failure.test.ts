import assert from "node:assert/strict";
import test from "node:test";
import {failedNodeExecution, nodeExecutionFailure} from "./task-graph-state.js";
import {NodeFailure} from "../../../domain/entities/node-failure.js";
import {nestedNodeFailureOf} from "./nested-node-failure.js";
import {type WorkflowNode} from "./task-definition.js";

const node = {id: "node.2", primitive: "prompt"} as WorkflowNode;
const details = {operator: "before", expected: "date", received: "29.09.2026"};
const failure = NodeFailure.of({code: "conditionOperandMismatch", message: "mismatch", details});

test("a failure value carries its stable code and details", () => {
  const executionFailure = failedNodeExecution(node, failure, []);

  assert.equal(executionFailure.failedNode.failureCode, "conditionOperandMismatch");
  assert.deepEqual(executionFailure.failedNode.failureDetails, details);
  assert.equal(executionFailure.message, "mismatch");
  assert.equal(executionFailure.cause, failure);
});

test("an ordinary exception keeps only its message", () => {
  const executionFailure = nodeExecutionFailure(node, new Error("kaputt"), []);

  assert.equal(executionFailure.failedNode.failureCode, undefined);
  assert.equal(executionFailure.message, "kaputt");
});

test("a nested plan passes its failure value to the outer node", () => {
  assert.equal(nestedNodeFailureOf(failedNodeExecution(node, failure, [])), failure);
});

test("an exception in a nested plan becomes an unexpected failure with its message", () => {
  const nested = nestedNodeFailureOf(nodeExecutionFailure(node, new Error("kaputt"), []));

  assert.equal(nested.code, "unexpected");
  assert.equal(nested.message, "kaputt");
});
