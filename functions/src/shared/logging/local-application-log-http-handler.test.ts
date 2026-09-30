import {testingRoutes} from "../local/local-runtime-http-test-support.js";
import assert from "node:assert/strict";
import test from "node:test";
import {LocalApplicationLogHttpHandler} from "./local-application-log-http-handler.js";
import {LocalRuntimeRealtimeNotifier} from "../local/local-runtime-realtime-notifier.js";
import {type LocalApplicationLog, type LocalApplicationLogStore} from "./local-application-log-store.js";

test("lists recent local application logs through the loopback API", async () => {
  const handler = testingRoutes(new LocalApplicationLogHttpHandler(new StubLogStore(), "team-1", new LocalRuntimeRealtimeNotifier()));

  const response = await handler.handle({
    body: {}, method: "GET", url: "/v1/application-logs",
  });

  assert.deepEqual(response, {
    body: {items: [{
      id: "log-1",
      source: "runtime",
      level: "error",
      event: "task_run.failed",
      message: null,
      data: {runId: "run-1"},
      occurredAt: "2026-09-09T10:00:00.000Z",
    }]},
    statusCode: 200,
  });
});

test("accepts client logs and assigns trusted fields in the runtime", async () => {
  const store = new StubLogStore();
  const handler = testingRoutes(new LocalApplicationLogHttpHandler(store, "team-1", new LocalRuntimeRealtimeNotifier()));

  const response = await handler.handle({
    body: {
      level: "error",
      event: "client.flutter",
      message: "Unbehandelter Flutter-Fehler.",
      data: {error: "StateError"},
    },
    method: "POST",
    url: "/v1/application-logs",
  });

  assert.deepEqual(response, {body: {}, statusCode: 202});
  assert.equal(store.appended.length, 1);
  assert.deepEqual(store.appended[0], {
    ...store.appended[0],
    teamId: "team-1",
    source: "client",
    level: "error",
    event: "client.flutter",
    message: "Unbehandelter Flutter-Fehler.",
    data: {error: "StateError"},
  });
  assert.match(store.appended[0]?.id ?? "", /^[a-f0-9-]{36}$/);
});

class StubLogStore implements LocalApplicationLogStore {
  readonly appended: LocalApplicationLog[] = [];

  async append(log: LocalApplicationLog): Promise<void> {
    this.appended.push(log);
  }

  async recent(): Promise<LocalApplicationLog[]> {
    return [{
      id: "log-1",
      teamId: "team-1",
      source: "runtime",
      level: "error",
      event: "task_run.failed",
      message: null,
      data: {runId: "run-1"},
      occurredAt: "2026-09-09T10:00:00.000Z",
    }];
  }
}
