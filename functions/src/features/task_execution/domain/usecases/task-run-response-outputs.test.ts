import assert from "node:assert/strict";
import test from "node:test";
import {type TaskResumeState} from "../entities/task.js";
import {responseOutputsForTaskRun} from "./task-run-response-outputs.js";

test("maps a dialog submission to typed node outputs", () => {
  const outputs = responseOutputsForTaskRun(dialogResumeState(), "", {
    name: "Mila",
    age: 27,
    active: true,
    channel: "E-Mail",
  });

  assert.deepEqual(outputs, {
    text: {type: "string", value: '{"name":"Mila","age":27,"active":true,"channel":"E-Mail"}'},
    name: {type: "string", value: "Mila"},
    age: {type: "number", value: 27},
    active: {type: "boolean", value: true},
    channel: {type: "string", value: "E-Mail"},
  });
});

test("rejects a dialog submission with an invalid data type", () => {
  assert.throws(
    () => responseOutputsForTaskRun(dialogResumeState(), "", {
      name: "Mila", age: 27.5, active: true, channel: "E-Mail",
    }),
    /Ungültige Eingabe für "age"/,
  );
});

function dialogResumeState(): TaskResumeState {
  return {
    nodeResults: [{
      nodeId: "dialog", primitive: "dialogInput", status: "waitingForApproval", outputs: {},
      dialogInput: {
        instruction: "Bitte ausfüllen.",
        fields: [
          {name: "name", type: "string", options: []},
          {name: "age", type: "integer", options: []},
          {name: "active", type: "boolean", options: []},
          {name: "channel", type: "selection", options: ["E-Mail", "SMS"]},
        ],
      },
    }],
    variables: {}, remainingNodeIds: [], skippedNodeIds: [], waitingNodeId: "dialog",
  };
}
