import assert from "node:assert/strict";
import {mkdtemp, readFile} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join} from "node:path";
import test from "node:test";
import {CurrentRuntimeFieldCipher} from "../../../runtime_security/infrastructure/current-runtime-field-cipher.js";
import {createRuntimeKeyring} from "../../../runtime_security/infrastructure/runtime-keyring.js";
import {RuntimeSecretFileAccess} from "../../../runtime_security/infrastructure/runtime-secret-file-access.js";
import {FileMlTenantTokenStore, mlTenantTokenPath} from "./file-ml-tenant-token-store.js";

test("stores the token encrypted and reads it back", async () => {
  const root = await mkdtemp(join(tmpdir(), "ml-token-"));
  const store = new FileMlTenantTokenStore(root, new CurrentRuntimeFieldCipher(JSON.stringify(createRuntimeKeyring())), new RuntimeSecretFileAccess());

  await store.save({tenantId: "workspace-a", token: "nml_secret"});

  assert.deepEqual(await store.load(), {tenantId: "workspace-a", token: "nml_secret"});
  assert.doesNotMatch(await readFile(mlTenantTokenPath(root), "utf8"), /nml_secret/);
  await store.clear();
  assert.equal(await store.load(), null);
});
