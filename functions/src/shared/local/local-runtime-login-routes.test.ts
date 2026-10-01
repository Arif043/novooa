import assert from "node:assert/strict";
import test from "node:test";
import {testingRoutes} from "./local-runtime-http-test-support.js";
import {loginRoutes} from "./local-runtime-login-routes.js";

test("login needs only password verification and session creation", async () => {
  let createdSessions = 0;
  const handler = testingRoutes(loginRoutes, {
    credentials: {verifyPassword: async (password: string) => password === "correct"},
    sessions: {createSession: async () => { createdSessions += 1; return "session-token"; }},
  });
  const response = await handler.handle({method: "POST", url: "/v1/auth/login", body: {password: "correct"}});
  assert.deepEqual(response, {body: {token: "session-token"}, statusCode: 200});
  assert.equal(createdSessions, 1);
});

test("invalid credentials do not create sessions", async () => {
  const handler = testingRoutes(loginRoutes, {
    credentials: {verifyPassword: async () => false},
    sessions: {createSession: async () => { throw new Error("Must not create a session."); }},
  });
  for (const body of [{password: "wrong"}, {password: ""}]) {
    assert.equal((await handler.handle({method: "POST", url: "/v1/auth/login", body}))?.statusCode, 401);
  }
});

test("a request without password is rejected by the schema", async () => {
  const handler = testingRoutes(loginRoutes, {
    credentials: {verifyPassword: async () => { throw new Error("Must not verify a password."); }},
    sessions: {createSession: async () => { throw new Error("Must not create a session."); }},
  });
  const response = await handler.handle({method: "POST", url: "/v1/auth/login", body: {}});
  assert.deepEqual(response, {statusCode: 400,
    body: {error: "Ungültige Anfrage.", code: "invalid_request", field: "body"}});
});

test("unrelated requests do not invoke login dependencies", async () => {
  const handler = testingRoutes(loginRoutes, {
    credentials: {verifyPassword: async () => { throw new Error("Must not verify a password."); }},
    sessions: {createSession: async () => { throw new Error("Must not create a session."); }},
  });
  assert.equal(await handler.handle({method: "GET", url: "/v1/tasks", body: {}}), null);
});
