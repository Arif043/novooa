import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {readFile, stat} from "node:fs/promises";
import {join} from "node:path";
import test from "node:test";
import {EncryptedSQLiteLanguageModelSecretStore} from "../../language_models/infrastructure/local/encrypted-sqlite-language-model-secret-store.js";
import {FileRuntimeLicenseStore} from "../../licensing/infrastructure/local/file-local-runtime-license-store.js";
import {FileMlTenantTokenStore} from "../../machine_learning/infrastructure/local/file-ml-tenant-token-store.js";
import {RotateRuntimeMasterKey} from "../domain/usecases/rotate-runtime-master-key.js";
import {EnvelopeRuntimeFieldCipher} from "./envelope-runtime-field-cipher.js";
import {FileRuntimeKeyRepository} from "./file-runtime-key-repository.js";
import {LocalRuntimeSecretRotationStore} from "./local-runtime-secret-rotation-store.js";
import {parseRuntimeKeyring} from "./runtime-keyring.js";
import {RuntimeSecretFileAccess} from "./runtime-secret-file-access.js";
import {rotationFixture} from "./runtime-rotation-test-fixture.js";

test("rotates SQLite secrets and license data without changing their payload ciphertext", async () => {
  const fixture = await rotationFixture();
  try {
    const before = await storedValues(fixture);
    const workflow = rotationWorkflow(fixture);
    assert.equal(await workflow.execute(), 3);
    const keyring = parseRuntimeKeyring(await readFile(fixture.keyFile, "utf8"));
    assert.equal(keyring.rotationPending, false);
    assert.equal(Object.keys(keyring.keys).length, 2);
    const after = await storedValues(fixture);
    assert.deepEqual(after.map(payload), before.map(payload));
    assert.notDeepEqual(after, before);
    await verifyFixture(fixture);
    assert.equal((await stat(fixture.keyFile)).mode & 0o777, 0o600);
  } finally {
    await fixture.cleanup();
  }
});

test("resumes an interrupted rotation using the same staged master key", async () => {
  const fixture = await rotationFixture();
  const keys = new FileRuntimeKeyRepository(fixture.keyFile);
  try {
    const cipher = await keys.beginRotation();
    await fixture.database.run(sql`UPDATE language_model_secrets SET encrypted_value = ${cipher.rewrap((await storedValues(fixture))[0], ["language-model-secrets", "model/a", "api-key"])} WHERE secret_ref = ${"model/a"}`);
    const staged = await readFile(fixture.keyFile, "utf8");
    assert.equal(parseRuntimeKeyring(staged).rotationPending, true);
    assert.equal(await rotationWorkflow(fixture).execute(true), 2);
    const completed = parseRuntimeKeyring(await readFile(fixture.keyFile, "utf8"));
    assert.equal(completed.activeKeyId, parseRuntimeKeyring(staged).activeKeyId);
    assert.equal(Object.keys(completed.keys).length, 1);
    await verifyFixture(fixture);
  } finally {
    await fixture.cleanup();
  }
});

test("does not retire any keys when a persisted secret fails authentication", async () => {
  const fixture = await rotationFixture();
  try {
    const values = await storedValues(fixture);
    await fixture.database.run(sql`UPDATE language_model_secrets SET encrypted_value = ${values[0]} WHERE secret_ref = ${"model/b"}`);
    await assert.rejects(rotationWorkflow(fixture).execute(true));
    const keyring = parseRuntimeKeyring(await readFile(fixture.keyFile, "utf8"));
    assert.equal(keyring.rotationPending, true);
    assert.equal(Object.keys(keyring.keys).length, 2);
  } finally {
    await fixture.cleanup();
  }
});

test("does not silently delete a license encrypted under a missing master key", async () => {
  const fixture = await rotationFixture();
  try {
    const keys = new FileRuntimeKeyRepository(fixture.keyFile);
    await keys.beginRotation();
    const keyring = parseRuntimeKeyring(await readFile(fixture.keyFile, "utf8"));
    keyring.keys = {[keyring.activeKeyId]: keyring.keys[keyring.activeKeyId]};
    const store = new FileRuntimeLicenseStore(fixture.root, new EnvelopeRuntimeFieldCipher(JSON.stringify(keyring)));
    await assert.rejects(store.load(), /Master-Key fehlt/);
    await stat(join(fixture.root, "credentials", "license-state.json"));
  } finally {
    await fixture.cleanup();
  }
});

type Fixture = Awaited<ReturnType<typeof rotationFixture>>;

function rotationWorkflow(fixture: Fixture): RotateRuntimeMasterKey {
  return new RotateRuntimeMasterKey(new FileRuntimeKeyRepository(fixture.keyFile),
    new LocalRuntimeSecretRotationStore(fixture.database, fixture.root));
}

async function storedValues(fixture: Fixture): Promise<string[]> {
  const rows = await fixture.database.all <{encrypted_value: string}>(sql`SELECT encrypted_value FROM language_model_secrets ORDER BY secret_ref`);
  const license = JSON.parse(await readFile(join(fixture.root, "credentials", "license-state.json"), "utf8"));
  return [...rows.map((row) => row.encrypted_value), license.encryptedActivationSecret];
}

function payload(encrypted: string): unknown {
  return JSON.parse(encrypted).payload;
}

async function verifyFixture(fixture: Fixture): Promise<void> {
  const cipher = new EnvelopeRuntimeFieldCipher(await readFile(fixture.keyFile, "utf8"));
  const store = new EncryptedSQLiteLanguageModelSecretStore(fixture.database, cipher);
  assert.equal(await store.read("model/a"), "key-a");
  assert.equal(await store.read("model/b"), "key-b");
  assert.equal((await new FileRuntimeLicenseStore(fixture.root, cipher).load())?.activationSecret, "activation-secret");
}

test("rotates the stored ML service token along with the other secrets", async () => {
  const fixture = await rotationFixture();
  try {
    const before = new EnvelopeRuntimeFieldCipher(await readFile(fixture.keyFile, "utf8"));
    await new FileMlTenantTokenStore(fixture.root, before, new RuntimeSecretFileAccess()).save({tenantId: "workspace-a", token: "nml_secret"});

    assert.equal(await rotationWorkflow(fixture).execute(), 4);

    const after = new EnvelopeRuntimeFieldCipher(await readFile(fixture.keyFile, "utf8"));
    const stored = await new FileMlTenantTokenStore(fixture.root, after, new RuntimeSecretFileAccess()).load();
    assert.deepEqual(stored, {tenantId: "workspace-a", token: "nml_secret"});
  } finally {
    await fixture.cleanup();
  }
});
