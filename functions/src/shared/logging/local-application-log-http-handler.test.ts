import assert from "node:assert/strict";
import test from "node:test";
import {LocalApplicationLogHttpHandler} from "./local-application-log-http-handler.js";
import {type LocalApplicationLog, type LocalApplicationLogStore} from "./local-application-log-store.js";

test("lists recent local application logs through the loopback API", async () => {
  const handler = new LocalApplicationLogHttpHandler(new StubLogStore(), "team-1");

  const response = await handler.handle({
    body: {}, method: "GET", url: "/v1/application-logs",
  });

  assert.deepEqual(response, {
    body: {items: [{
      id: "log-1",
      level: "error",
      event: "task_run.failed",
      message: null,
      data: {runId: "run-1"},
      occurredAt: "2026-09-09T10:00:00.000Z",
    }]},
    statusCode: 200,
  });
});

class StubLogStore implements LocalApplicationLogStore {
  async append(): Promise<void> {}

  async recent(): Promise<LocalApplicationLog[]> {
    return [{
      id: "log-1",
      teamId: "team-1",
      level: "error",
      event: "task_run.failed",
      message: null,
      data: {runId: "run-1"},
      occurredAt: "2026-09-09T10:00:00.000Z",
    }];
  }
}
