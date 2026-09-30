import assert from "node:assert/strict";
import test from "node:test";
import {ActivateRuntime} from "./activate-runtime.js";

const context = {licenseId: "license", licenseName: "Standalone", workspaceId: "workspace", expiresAt: "2030-01-01"};

test("activation starts the licensed workspace only after license validation", async () => {
  const calls: string[] = [];
  const activate = new ActivateRuntime({activate: async ({activationToken}) => {
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
  const activate = new ActivateRuntime({activate: async () => {throw new Error("Invalid license");}},
    async () => {started = true;});
  await assert.rejects(activate.execute("invalid"), /Invalid license/);
  assert.equal(started, false);
});

test("a failed workspace startup does not report activation success", async () => {
  const activate = new ActivateRuntime({activate: async () => context},
    async () => {throw new Error("Workspace unavailable");});
  await assert.rejects(activate.execute("token"), /Workspace unavailable/);
});
