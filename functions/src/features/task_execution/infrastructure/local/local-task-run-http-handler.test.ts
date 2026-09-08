import assert from "node:assert/strict";
import test from "node:test";
import {type TaskWorkflow} from "../../domain/usecases/task-workflow.js";
import {LocalTaskRunHttpHandler} from "./local-task-run-http-handler.js";

test("starts a task run for the local workspace user", async () => {
  const calls: Array<{taskId: string; context: string; uid: string}> = [];
  const handler = new LocalTaskRunHttpHandler(taskWorkflow(calls), "local-user");

  const response = await handler.handle({
    body: {taskId: "task-1", context: "Morgen"},
    method: "POST",
    url: "/v1/task-runs",
  });

  assert.deepEqual(response, {
    body: {runId: "run-1", taskId: "task-1", status: "queued"},
    statusCode: 202,
  });
  assert.deepEqual(calls, [{taskId: "task-1", context: "Morgen", uid: "local-user"}]);
});

test("rejects an invalid local task run request", async () => {
  const handler = new LocalTaskRunHttpHandler(taskWorkflow([]), "local-user");

  const response = await handler.handle({
    body: {context: "Morgen"}, method: "POST", url: "/v1/task-runs",
  });

  assert.deepEqual(response, {
    body: {error: "taskId muss ein nicht leerer String sein."}, statusCode: 400,
  });
});

test("reviews a local task run", async () => {
  const handler = new LocalTaskRunHttpHandler(taskWorkflow([]), "local-user");

  const response = await handler.handle({
    body: {decision: "approve", formValues: {}, runId: "run-1"},
    method: "POST",
    url: "/v1/task-runs/review",
  });

  assert.deepEqual(response, {
    body: {runId: "run-1", status: "rejected"}, statusCode: 200,
  });
});

function taskWorkflow(
  calls: Array<{taskId: string; context: string; uid: string}>,
): TaskWorkflow {
  return {
    start: async (input, context) => {
      calls.push({...input, uid: context.uid});
      return {runId: "run-1", taskId: input.taskId, status: "queued"};
    },
    review: async () => ({runId: "run-1", status: "rejected"}),
    dispatch: async () => undefined,
  };
}
