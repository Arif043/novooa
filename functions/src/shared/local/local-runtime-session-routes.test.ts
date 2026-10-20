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
