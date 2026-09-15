import assert from "node:assert/strict";
import {mkdtemp, readFile, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join} from "node:path";
import test from "node:test";
import {CredentialCipher} from "../../../communication/infrastructure/security/credential-cipher.js";
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
        expiresAt: undefined,
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

function cipher(): CredentialCipher {
  return new CredentialCipher(Buffer.alloc(32, 7).toString("base64"), "TEST_MASTER_KEY");
}
