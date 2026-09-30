import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import test from "node:test";
import {LocalRuntimeSecurity} from "./local-runtime-security.js";
import {rotationFixture} from "../../features/runtime_security/infrastructure/runtime-rotation-test-fixture.js";
import {parseRuntimeKeyring} from "../../features/runtime_security/infrastructure/runtime-keyring.js";
import {writeDurableSecretFile} from "../../features/runtime_security/infrastructure/durable-secret-file.js";
import {EncryptedSQLiteLanguageModelSecretStore} from "../../features/language_models/infrastructure/local/encrypted-sqlite-language-model-secret-store.js";

test("runtime lifecycle automatically rotates an overdue key and updates existing consumers", async () => {
  const fixture = await rotationFixture();
  const keyring = parseRuntimeKeyring(await readFile(fixture.keyFile, "utf8"));
  keyring.lastRotatedAt = "2026-01-01T00:00:00.000Z";
  await writeDurableSecretFile(fixture.keyFile, JSON.stringify(keyring));
  const security = new LocalRuntimeSecurity(fixture.keyFile, JSON.stringify(keyring), fixture.database,
    fixture.root, () => new Date("2026-02-01T00:00:00Z"));
  const store = new EncryptedSQLiteLanguageModelSecretStore(fixture.database, security.cipher);
  try {
    security.start();
    await security.stop();
    const completed = parseRuntimeKeyring(await readFile(fixture.keyFile, "utf8"));
    assert.notEqual(completed.activeKeyId, keyring.activeKeyId);
    assert.equal(completed.rotationPending, false);
    assert.equal(await store.read("model/a"), "key-a");
    assert.equal(completed.lastRotatedAt, "2026-02-01T00:00:00.000Z");
  } finally { await security.stop(); await fixture.cleanup(); }
});
