import assert from "node:assert/strict";
import test from "node:test";
import {RuntimeAlreadyActivatedError} from "../entities/runtime-license-errors.js";
import {ActivateRuntime} from "./activate-runtime.js";

const context = {licenseId: "license", licenseName: "Standalone", workspaceId: "workspace", expiresAt: "2030-01-01", maxUsers: 5};

test("activation starts the licensed workspace only after license validation", async () => {
  const calls: string[] = [];
  const activate = new ActivateRuntime({activeContext: () => null, matchesActivationToken: () => false, activate: async ({activationToken}) => {
    calls.push(activationToken);
    return context;
  }}, async (licensedWorkspace) => {
    assert.equal(licensedWorkspace, context);
    calls.push("workspace");
  });
  assert.equal(await activate.execute("token"), context);
  assert.deepEqual(calls, ["token", "workspace"]);
});

test("a rejected license never starts a workspace", async () => {
  let started = false;
  const activate = new ActivateRuntime({activeContext: () => null, matchesActivationToken: () => false, activate: async () => {throw new Error("Invalid license");}},
    async () => {started = true;});
  await assert.rejects(activate.execute("invalid"), /Invalid license/);
  assert.equal(started, false);
});

test("a failed workspace startup does not report activation success", async () => {
  const activate = new ActivateRuntime({activeContext: () => null, matchesActivationToken: () => false, activate: async () => context},
    async () => {throw new Error("Workspace unavailable");});
  await assert.rejects(activate.execute("token"), /Workspace unavailable/);
});

test("an already licensed runtime confirms its license for the redeemed token", async () => {
  let redeemed = false;
  let startedWorkspace: unknown;
  const activate = new ActivateRuntime({
    activeContext: () => context,
    matchesActivationToken: (token) => token === "redeemed-token",
    activate: async () => {redeemed = true; return context;},
  }, async (licensedWorkspace) => {startedWorkspace = licensedWorkspace;});
  assert.equal(await activate.execute("redeemed-token"), context);
  assert.equal(redeemed, false);
  assert.equal(startedWorkspace, context);
});

test("an already licensed runtime rejects a foreign token", async () => {
  const activate = new ActivateRuntime({
    activeContext: () => context,
    matchesActivationToken: () => false,
    activate: async () => context,
  }, async () => undefined);
  await assert.rejects(activate.execute("foreign-token"), RuntimeAlreadyActivatedError);
});
