import assert from "node:assert/strict";
import test from "node:test";
import {nodeExecutionFailure} from "./task-graph-state.js";
import {NodeFailedError} from "../../../domain/entities/node-execution-failure.js";
import {type WorkflowNode} from "./task-definition.js";

const node = {id: "node.2", primitive: "prompt"} as WorkflowNode;

test("a node failure with a reason carries its stable code", () => {
  const error = new NodeFailedError({code: "responseTruncated", message: "Kontextfenster erschöpft."});

  const failure = nodeExecutionFailure(node, error, []);

  assert.equal(failure.failedNode.failureCode, "responseTruncated");
  assert.equal(failure.message, "Kontextfenster erschöpft.");
  assert.equal(failure.cause, error);
});

test("an ordinary exception keeps only its message", () => {
  const failure = nodeExecutionFailure(node, new Error("kaputt"), []);

  assert.equal(failure.failedNode.failureCode, undefined);
  assert.equal(failure.message, "kaputt");
});

test("the details of a reason reach the failed node for translation", () => {
  const details = {operator: "before", expected: "date", received: "29.09.2026"};
  const error = new NodeFailedError({code: "conditionOperandMismatch", message: "mismatch", details});

  const failure = nodeExecutionFailure(node, error, []);

  assert.deepEqual(failure.failedNode.failureDetails, details);
});
