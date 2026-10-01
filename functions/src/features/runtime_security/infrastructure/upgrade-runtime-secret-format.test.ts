import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {join} from "node:path";
import test from "node:test";
import {CredentialCipher} from "../../communication/infrastructure/security/credential-cipher.js";
import {parseRuntimeKeyring} from "./runtime-keyring.js";
import {rotationFixture} from "./runtime-rotation-test-fixture.js";
import {UpgradeRuntimeSecretFormat} from "./upgrade-runtime-secret-format.js";
import {writeDurableSecretFile} from "./durable-secret-file.js";
import {EncryptedSQLiteLanguageModelSecretStore} from "../../language_models/infrastructure/local/encrypted-sqlite-language-model-secret-store.js";
import {FileRuntimeLicenseStore} from "../../licensing/infrastructure/local/file-local-runtime-license-store.js";

test("upgrades existing model and license secrets without changing their plaintext", async () => {
  const fixture = await legacyFixture();
  try {
    const workflow = new UpgradeRuntimeSecretFormat(fixture.database, fixture.root, fixture.keyring);
    await workflow.execute();
    const store = new EncryptedSQLiteLanguageModelSecretStore(fixture.database, fixture.cipher);
    assert.equal(await store.read("model/a"), "key-a");
    assert.equal((await new FileRuntimeLicenseStore(fixture.root, fixture.cipher).load())?.activationSecret, "activation-secret");
    const persisted = await readFile(fixture.licensePath, "utf8");
    await workflow.execute();
    assert.equal(await readFile(fixture.licensePath, "utf8"), persisted);
  } finally { await fixture.cleanup(); }
});

test("refuses a corrupt legacy value and leaves existing model values intact", async () => {
  const fixture = await legacyFixture();
  try {
    await fixture.database.run(sql`UPDATE language_model_secrets SET encrypted_value = 'corrupt' WHERE secret_ref = 'model/b'`);
    const before = await fixture.database.get <{encrypted_value: string}>(sql`SELECT encrypted_value FROM language_model_secrets WHERE secret_ref = 'model/a'`);
    await assert.rejects(new UpgradeRuntimeSecretFormat(fixture.database, fixture.root, fixture.keyring).execute(), /nicht entschlüsselt/);
    const after = await fixture.database.get <{encrypted_value: string}>(sql`SELECT encrypted_value FROM language_model_secrets WHERE secret_ref = 'model/a'`);
    assert.deepEqual(after, before);
  } finally { await fixture.cleanup(); }
});

async function legacyFixture() {
  const fixture = await rotationFixture();
  const keyring = await readFile(fixture.keyFile, "utf8");
  const keys = parseRuntimeKeyring(keyring);
  const legacy = new CredentialCipher(keys.keys[keys.activeKeyId]);
  const licensePath = join(fixture.root, "credentials", "license-state.json");
  const document = JSON.parse(await readFile(licensePath, "utf8"));
  await writeDurableSecretFile(licensePath, JSON.stringify({...document, encryptedActivationSecret: legacy.encrypt("activation-secret")}));
  await fixture.database.run(sql`UPDATE language_model_secrets SET encrypted_value = ${legacy.encrypt("key-a")} WHERE secret_ref = 'model/a'`);
  return {...fixture, keyring, licensePath};
}
