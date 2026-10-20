import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import assert from "node:assert/strict";
import test from "node:test";
import {type TaskWorkflow} from "../../domain/usecases/task-workflow.js";
import {type ApplicationLogger, type LogData} from "../../../../shared/logging/application-logger.js";
import {taskRunRoutes} from "./local-task-run-routes.js";
import {testWorkspace} from "../../../../shared/local/local-runtime-http-test-support.js";
import {LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";

test("starts a task run for the local workspace user", async () => {
  const calls: Array<{taskId: string; context: string; uid: string}> = [];
  const handler = testingRoutes(taskRunRoutes, {notifier: new LocalRuntimeRealtimeNotifier()}, testWorkspace({taskWorkflow: taskWorkflow(calls), logger: new TestLogger()}));

  const response = await handler.handle({
    body: {taskId: "task-1", context: "Morgen"},
    method: "POST",
    url: "/v1/task-runs",
  });

  assert.deepEqual(response, {
    body: {runId: "run-1", taskId: "task-1", status: "queued"},
    statusCode: 202,
  });
  assert.deepEqual(calls, [{taskId: "task-1", context: "Morgen", uid: "user-1"}]);
});

test("rejects an invalid local task run request", async () => {
  const handler = testingRoutes(taskRunRoutes, {notifier: new LocalRuntimeRealtimeNotifier()}, testWorkspace({taskWorkflow: taskWorkflow([]), logger: new TestLogger()}));

  const response = await handler.handle({
    body: {context: "Morgen"}, method: "POST", url: "/v1/task-runs",
  });

  assert.deepEqual(response, {
    body: {
      failure: {
        code: "invalidTaskId",
        message: "taskId muss ein nicht leerer String sein.",
      },
    },
    statusCode: 400,
  });
});

test("reviews a local task run", async () => {
  const handler = testingRoutes(taskRunRoutes, {notifier: new LocalRuntimeRealtimeNotifier()}, testWorkspace({taskWorkflow: taskWorkflow([]), logger: new TestLogger()}));

  const response = await handler.handle({
    body: {decision: "approve", formValues: {}, runId: "run-1"},
    method: "POST",
    url: "/v1/task-runs/review",
  });

  assert.deepEqual(response, {
    body: {runId: "run-1", status: "rejected"}, statusCode: 200,
  });
});

test("logs unexpected task run errors and hides their details", async () => {
  const logger = new TestLogger();
  const workflow = taskWorkflow([]);
  workflow.start = async () => {
    throw new Error("database unavailable");
  };
  const handler = testingRoutes(taskRunRoutes, {notifier: new LocalRuntimeRealtimeNotifier()}, testWorkspace({taskWorkflow: workflow, logger: logger}));

  const response = await handler.handle({
    body: {taskId: "task-1"}, method: "POST", url: "/v1/task-runs",
  });

  assert.deepEqual(response, {
    body: {error: "Die lokale Runtime konnte die Anfrage nicht verarbeiten."},
    statusCode: 500,
  });
  assert.deepEqual(logger.exceptions, [{
    data: {userId: "user-1"},
    error: new Error("database unavailable"),
    event: "local_task_run_routes.start_failed",
  }]);
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

class TestLogger implements ApplicationLogger {
  readonly exceptions: Array<{event: string; error: unknown; data: LogData}> = [];

  info(): void {}
  error(): void {}
  readableInfo(): void {}
  readableError(): void {}

  exception(event: string, error: unknown, data: LogData = {}): void {
    this.exceptions.push({event, error, data});
  }
}
