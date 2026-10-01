import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {join} from "node:path";
import test from "node:test";
import {rotationFixture} from "./runtime-rotation-test-fixture.js";
import {CurrentRuntimeFieldCipher} from "./current-runtime-field-cipher.js";
import {RuntimeSecretFileAccess} from "./runtime-secret-file-access.js";
import {FileRuntimeKeyRepository} from "./file-runtime-key-repository.js";
import {LocalRuntimeSecretRotationStore} from "./local-runtime-secret-rotation-store.js";
import {RotateRuntimeMasterKey} from "../domain/usecases/rotate-runtime-master-key.js";
import {EncryptedSQLiteLanguageModelSecretStore} from "../../language_models/infrastructure/local/encrypted-sqlite-language-model-secret-store.js";
import {FileRuntimeLicenseStore} from "../../licensing/infrastructure/local/file-local-runtime-license-store.js";

test("existing consumers adopt the active master key while concurrent updates survive rotation", async () => {
  const fixture = await liveFixture();
  try {
    const writes: Promise<void>[] = [];
    let updated = false;
    const keys = new FileRuntimeKeyRepository(fixture.keyFile, (keyring) => {
      fixture.current.update(keyring);
      if (updated) return;
      updated = true;
      writes.push(fixture.models.write("model/a", "updated-api-key"));
      writes.push(fixture.licenses.save({...fixture.activation, activationSecret: "updated-activation"}));
    });
    await new RotateRuntimeMasterKey(keys, fixture.rotationStore).execute();
    await Promise.all(writes);
    await assertLiveValues(fixture);
  } finally { await fixture.cleanup(); }
});

test("transaction-bound secret writes encrypt with the key active when they execute", async () => {
  const fixture = await liveFixture();
  try {
    let unblock: () => void = () => {};
    const blocked = new Promise<void>((resolve) => { unblock = resolve; });
    const transaction = fixture.database.transaction(async (tx) => {
      await blocked;
      await fixture.models.withDatabase(tx).write("model/a", "queued-api-key");
    });
    const keys = new FileRuntimeKeyRepository(fixture.keyFile, (keyring) => fixture.current.update(keyring));
    await keys.beginRotation();
    unblock(); await transaction;
    const row = await fixture.database.get <{encrypted_value: string}>(sql`SELECT encrypted_value FROM language_model_secrets WHERE secret_ref = 'model/a'`);
    assert.ok(row && fixture.current.usesActiveKey(row.encrypted_value));
    assert.equal(await fixture.models.read("model/a"), "queued-api-key");
  } finally { await fixture.cleanup(); }
});

test("license saving and rewrapping are serialized without losing a newer activation", async () => {
  const fixture = await liveFixture();
  try {
    const keys = new FileRuntimeKeyRepository(fixture.keyFile, (keyring) => fixture.current.update(keyring));
    const rotation = new RotateRuntimeMasterKey(keys, fixture.rotationStore).execute();
    const saving = fixture.licenses.save({...fixture.activation, activationSecret: "latest-activation"});
    await Promise.all([rotation, saving]);
    assert.equal((await fixture.licenses.load())?.activationSecret, "latest-activation");
    const persisted = JSON.parse(await readFile(join(fixture.root, "credentials", "license-state.json"), "utf8"));
    assert.ok(fixture.current.usesActiveKey(persisted.encryptedActivationSecret));
  } finally { await fixture.cleanup(); }
});

async function liveFixture() {
  const fixture = await rotationFixture();
  const current = new CurrentRuntimeFieldCipher(await readFile(fixture.keyFile, "utf8"));
  const access = new RuntimeSecretFileAccess();
  const licenses = new FileRuntimeLicenseStore(fixture.root, current, access);
  const activation = await licenses.load();
  assert.ok(activation);
  return {...fixture, current, licenses, activation,
    models: new EncryptedSQLiteLanguageModelSecretStore(fixture.database, current),
    rotationStore: new LocalRuntimeSecretRotationStore(fixture.database, fixture.root, access)};
}

async function assertLiveValues(fixture: Awaited<ReturnType<typeof liveFixture>>): Promise<void> {
  assert.equal(await fixture.models.read("model/a"), "updated-api-key");
  assert.equal(await fixture.models.read("model/b"), "key-b");
  assert.equal((await fixture.licenses.load())?.activationSecret, "updated-activation");
  await fixture.rotationStore.verifySecrets(fixture.current);
}
