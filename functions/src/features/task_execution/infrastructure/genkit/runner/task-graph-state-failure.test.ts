import assert from "node:assert/strict";
import test from "node:test";
import {failedNodeExecution, nodeExecutionFailure} from "./task-graph-state.js";
import {NodeFailure} from "../../../domain/entities/node-failure.js";
import {NestedNodeFailedException} from "./nested-node-failed-exception.js";
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

test("a failure from a nested plan keeps its code at the outer node", () => {
  const executionFailure = nodeExecutionFailure(node, new NestedNodeFailedException(failure), []);

  assert.equal(executionFailure.failedNode.failureCode, "conditionOperandMismatch");
  assert.deepEqual(executionFailure.failedNode.failureDetails, details);
});

test("an ordinary exception keeps only its message", () => {
  const executionFailure = nodeExecutionFailure(node, new Error("kaputt"), []);

  assert.equal(executionFailure.failedNode.failureCode, undefined);
  assert.equal(executionFailure.message, "kaputt");
});
