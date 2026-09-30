import assert from "node:assert/strict";
import test from "node:test";
import {LocalRuntimeLoginHttpHandler} from "./local-runtime-login-http-handler.js";

test("login needs only password verification and session creation", async () => {
  let createdSessions = 0;
  const handler = new LocalRuntimeLoginHttpHandler(
    {verifyPassword: async (password: string) => password === "correct"},
    {createSession: async () => { createdSessions += 1; return "session-token"; }},
  );
  const response = await handler.handle({method: "POST", url: "/v1/auth/login", body: {password: "correct"}});
  assert.deepEqual(response, {body: {token: "session-token"}, statusCode: 200});
  assert.equal(createdSessions, 1);
});

test("invalid credentials do not create sessions", async () => {
  const handler = new LocalRuntimeLoginHttpHandler(
    {verifyPassword: async () => false},
    {createSession: async () => { throw new Error("Must not create a session."); }},
  );
  for (const body of [{password: "wrong"}, {}]) {
    assert.equal((await handler.handle({method: "POST", url: "/v1/auth/login", body}))?.statusCode, 401);
  }
});

test("unrelated requests do not invoke login dependencies", async () => {
  const handler = new LocalRuntimeLoginHttpHandler(
    {verifyPassword: async () => { throw new Error("Must not verify a password."); }},
    {createSession: async () => { throw new Error("Must not create a session."); }},
  );
  assert.equal(await handler.handle({method: "GET", url: "/v1/tasks", body: {}}), null);
});
