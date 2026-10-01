import assert from "node:assert/strict";
import {mkdir, mkdtemp, readFile, rm, writeFile} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join} from "node:path";
import test from "node:test";
import {EnvelopeRuntimeFieldCipher} from "../../../runtime_security/infrastructure/envelope-runtime-field-cipher.js";
import {createRuntimeKeyring} from "../../../runtime_security/infrastructure/runtime-keyring.js";
import {FileRuntimeLicenseStore} from "./file-local-runtime-license-store.js";

test("encrypts the activation secret in the runtime license state", async () => {
  const runtimeRoot = await mkdtemp(join(tmpdir(), "novooa-license-"));
  const store = new FileRuntimeLicenseStore(runtimeRoot, cipher());
  const state = {
    license: {
      signature: "signature",
      payload: {
        licenseId: "license-1",
        licenseName: "Beispiel GmbH",
        activationId: "activation-1",
        workspaceId: "workspace-1",
        issuedAt: "2026-09-15T10:00:00.000Z",
        expiresAt: "2026-12-31T23:59:59.000Z",
      },
    },
    activationSecret: "activation-secret",
  };

  try {
    await store.save(state);
    const persisted = await readFile(join(runtimeRoot, "credentials", "license-state.json"), "utf8");

    assert.doesNotMatch(persisted, /activation-secret/);
    assert.deepEqual(await store.load(), state);
    await store.clear();
    assert.equal(await store.load(), null);
  } finally {
    await rm(runtimeRoot, {recursive: true, force: true});
  }
});

test("removes a legacy license without an expiry date", async () => {
  const runtimeRoot = await mkdtemp(join(tmpdir(), "novooa-license-"));
  const credentials = join(runtimeRoot, "credentials");
  const encryption = cipher();
  const store = new FileRuntimeLicenseStore(runtimeRoot, encryption);

  try {
    await mkdir(credentials, {recursive: true});
    await writeFile(join(credentials, "license-state.json"), JSON.stringify({
      license: {signature: "signature", payload: {
        licenseId: "license-1", licenseName: "Beispiel GmbH",
        activationId: "activation-1", workspaceId: "workspace-1",
        issuedAt: "2026-09-15T10:00:00.000Z",
      }},
      encryptedActivationSecret: "obsolete-format",
    }));

    assert.equal(await store.load(), null);
    await assert.rejects(readFile(join(credentials, "license-state.json"), "utf8"));
  } finally {
    await rm(runtimeRoot, {recursive: true, force: true});
  }
});

function cipher(): EnvelopeRuntimeFieldCipher {
  return new EnvelopeRuntimeFieldCipher(JSON.stringify(createRuntimeKeyring()));
}

test("keeps the activation token proof for the first-time setup", async () => {
  const runtimeRoot = await mkdtemp(join(tmpdir(), "novooa-license-"));
  const store = new FileRuntimeLicenseStore(runtimeRoot, cipher());
  const state = {
    license: {
      signature: "signature",
      payload: {
        licenseId: "license-1", licenseName: "Beispiel GmbH", activationId: "activation-1",
        workspaceId: "workspace-1", issuedAt: "2026-09-15T10:00:00.000Z", expiresAt: "2026-12-31T23:59:59.000Z",
      },
    },
    activationSecret: "activation-secret",
    activationTokenHash: "a".repeat(64),
  };
  try {
    await store.save(state);
    assert.deepEqual(await store.load(), state);
  } finally {
    await rm(runtimeRoot, {recursive: true, force: true});
  }
});
