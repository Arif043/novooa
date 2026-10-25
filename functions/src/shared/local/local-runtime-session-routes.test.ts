import assert from "node:assert/strict";
import test from "node:test";
import {testingRoutes} from "./local-runtime-http-test-support.js";
import {sessionRoutes} from "./local-runtime-session-routes.js";

function routesWithLog() {
  const calls: string[] = [];
  const handler = testingRoutes(sessionRoutes, {
    sessions: {
      deleteSession: async (token: string) => { calls.push(`delete:${token}`); },
      deleteOtherSessions: async (token: string, uid: string) => { calls.push(`deleteOthers:${token}:${uid}`); return 3; },
      isActive: async (token: string) => token === "aktuell",
      listSessionsOf: async (uid: string, token: string) => {
        calls.push(`list:${uid}:${token}`);
        return [{id: "s1", current: true, createdAt: "2026-10-01T00:00:00.000Z", lastUsedAt: "2026-10-02T00:00:00.000Z",
          device: {app: "novooa", os: "macos" as const, browser: "Chrome"}}];
      },
      deleteOwnSession: async (uid: string, id: string, token: string) => {
        calls.push(`deleteOwn:${uid}:${id}:${token}`);
        return id === "s2";
      },
    },
    connections: {
      closeSession: (token: string) => { calls.push(`close:${token}`); },
      closeInactive: async (isAllowed: (token: string) => Promise<boolean>) => {
        calls.push(`closeInactive:${await isAllowed("aktuell")}:${await isAllowed("alt")}`);
      },
    },
  });
  return {handler, calls};
}

test("logout ends the requesting session and closes its realtime connections", async () => {
  const {handler, calls} = routesWithLog();

  const response = await handler.handle({
    method: "POST", url: "/v1/auth/logout", body: {}, headers: {authorization: "Bearer aktuell"},
  });

  assert.equal(response?.statusCode, 204);
  assert.deepEqual(calls, ["delete:aktuell", "close:aktuell"]);
});

test("revoke-others ends every other session and reports how many", async () => {
  const {handler, calls} = routesWithLog();

  const response = await handler.handle({
    method: "POST", url: "/v1/auth/sessions/revoke-others", body: {}, headers: {authorization: "Bearer aktuell"},
  });

  assert.deepEqual(response, {statusCode: 200, body: {revoked: 3}});
  assert.deepEqual(calls, ["deleteOthers:aktuell:user-1", "closeInactive:true:false"]);
});

test("without a session token nothing is ended", async () => {
  const {handler, calls} = routesWithLog();

  const response = await handler.handle({method: "POST", url: "/v1/auth/logout", body: {}});

  assert.equal(response?.statusCode, 401);
  assert.deepEqual(calls, []);
});

test("sessions lists the own sessions of the requesting account", async () => {
  const {handler, calls} = routesWithLog();

  const response = await handler.handle({method: "GET", url: "/v1/auth/sessions", body: undefined, headers: {authorization: "Bearer aktuell"}});

  assert.equal(response?.statusCode, 200);
  assert.deepEqual(response?.body, {items: [{id: "s1", current: true, createdAt: "2026-10-01T00:00:00.000Z",
    lastUsedAt: "2026-10-02T00:00:00.000Z", device: {app: "novooa", os: "macos", browser: "Chrome"}}]});
  assert.deepEqual(calls, ["list:user-1:aktuell"]);
});

test("deleting one session ends it and closes its realtime connections", async () => {
  const {handler, calls} = routesWithLog();

  const response = await handler.handle({method: "DELETE", url: "/v1/auth/sessions/s2", body: undefined, headers: {authorization: "Bearer aktuell"}});

  assert.equal(response?.statusCode, 204);
  assert.deepEqual(calls, ["deleteOwn:user-1:s2:aktuell", "closeInactive:true:false"]);
});

test("deleting a session that is not another own session answers 404", async () => {
  const {handler, calls} = routesWithLog();

  const response = await handler.handle({method: "DELETE", url: "/v1/auth/sessions/fremd", body: undefined, headers: {authorization: "Bearer aktuell"}});

  assert.equal(response?.statusCode, 404);
  assert.equal((response?.body as {code?: string}).code, "session_not_found");
  assert.deepEqual(calls, ["deleteOwn:user-1:fremd:aktuell"]);
});
