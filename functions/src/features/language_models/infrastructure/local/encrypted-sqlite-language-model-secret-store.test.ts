import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test from "node:test";
import {connectRuntimeDatabase} from "../../../../db/database.js";
import {EnvelopeRuntimeFieldCipher} from "../../../runtime_security/infrastructure/envelope-runtime-field-cipher.js";
import {createRuntimeKeyring} from "../../../runtime_security/infrastructure/runtime-keyring.js";
import {EncryptedSQLiteLanguageModelSecretStore} from "./encrypted-sqlite-language-model-secret-store.js";

test("encrypts API keys before storing them in SQLite", async () => {
  const database = connectRuntimeDatabase(":memory:");
  await database.run(sql`CREATE TABLE language_model_secrets (secret_ref TEXT PRIMARY KEY, encrypted_value TEXT NOT NULL, updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)`);
  const store = new EncryptedSQLiteLanguageModelSecretStore(database, testCipher());

  await store.write("language-model/connection-1", "provider-api-key");
  const stored = await database.get <{encrypted_value: string}>(sql`SELECT encrypted_value FROM language_model_secrets WHERE secret_ref = ${"language-model/connection-1"}`);

  assert.notEqual(stored?.encrypted_value, "provider-api-key");
  assert.equal(await store.read("language-model/connection-1"), "provider-api-key");
  await store.delete("language-model/connection-1");
  assert.equal(await store.read("language-model/connection-1"), null);
  database.$client.close();
});

function testCipher(): EnvelopeRuntimeFieldCipher {
  return new EnvelopeRuntimeFieldCipher(JSON.stringify(createRuntimeKeyring()));
}
