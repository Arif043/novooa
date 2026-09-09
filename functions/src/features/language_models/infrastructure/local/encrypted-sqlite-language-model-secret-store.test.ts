import assert from "node:assert/strict";
import {randomBytes} from "node:crypto";
import test from "node:test";
import {CredentialCipher} from "../../../communication/infrastructure/security/credential-cipher.js";
import {SqliteLocalSqlDatabase} from "../../../../shared/local/sqlite-local-sql-database.js";
import {EncryptedSQLiteLanguageModelSecretStore} from "./encrypted-sqlite-language-model-secret-store.js";

test("encrypts API keys before storing them in SQLite", async () => {
  const database = new SqliteLocalSqlDatabase(":memory:");
  await database.run(
    "CREATE TABLE language_model_secrets (secret_ref TEXT PRIMARY KEY, encrypted_value TEXT NOT NULL)",
  );
  const store = new EncryptedSQLiteLanguageModelSecretStore(database, testCipher());

  await store.write("language-model/connection-1", "provider-api-key");
  const stored = await database.get<{encrypted_value: string}>(
    "SELECT encrypted_value FROM language_model_secrets WHERE secret_ref = ?",
    ["language-model/connection-1"],
  );

  assert.notEqual(stored?.encrypted_value, "provider-api-key");
  assert.equal(await store.read("language-model/connection-1"), "provider-api-key");
  await store.delete("language-model/connection-1");
  assert.equal(await store.read("language-model/connection-1"), null);
  database.close();
});

function testCipher(): CredentialCipher {
  return new CredentialCipher(randomBytes(32).toString("base64"));
}
