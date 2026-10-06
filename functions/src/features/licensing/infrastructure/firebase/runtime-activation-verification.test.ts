import assert from "node:assert/strict";
import test from "node:test";
import {RuntimeLicenseError} from "./firestore-runtime-license-registry.js";
import {runtimeActivationVerdict} from "./runtime-activation-verification.js";

const license = {signature: "sig", payload: {licenseId: "l", licenseName: "n", activationId: "a",
  workspaceId: "w", issuedAt: "2026-01-01T00:00:00.000Z", expiresAt: "2027-01-01T00:00:00.000Z"}};
const registryThatThrows = (error?: Error) => ({
  async verifyActiveActivation() { if (error) throw error; return {}; },
});

test("an active activation is reported as active", async () => {
  assert.equal(await runtimeActivationVerdict(registryThatThrows(), license, "secret", new Date()), "active");
});

test("a deleted, released or foreign license is reported as revoked", async () => {
  const registry = registryThatThrows(new RuntimeLicenseError("Die Lizenz ist ungültig."));
  assert.equal(await runtimeActivationVerdict(registry, license, "secret", new Date()), "revoked");
});

test("a technical failure is not a verdict", async () => {
  const registry = registryThatThrows(new Error("Firestore nicht erreichbar"));
  await assert.rejects(runtimeActivationVerdict(registry, license, "secret", new Date()), /Firestore/);
});
