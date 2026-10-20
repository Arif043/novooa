import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import test from "node:test";
import {RuntimePassword} from "../../runtime_users/domain/entities/runtime-password.js";
import {SQLitePasswordCredentialRepository} from "../../runtime_users/infrastructure/local/sqlite-password-credential-repository.js";
import {RotateRuntimeMasterKey} from "../domain/usecases/rotate-runtime-master-key.js";
import {EnvelopeRuntimeFieldCipher} from "./envelope-runtime-field-cipher.js";
import {FileRuntimeKeyRepository} from "./file-runtime-key-repository.js";
import {LocalRuntimeSecretRotationStore} from "./local-runtime-secret-rotation-store.js";
import {rotationFixture} from "./runtime-rotation-test-fixture.js";

test("a master key rotation rewraps password hashes and the password keeps working", async () => {
  const fixture = await rotationFixture();
  try {
    await new SQLitePasswordCredentialRepository(fixture.database, fixture.cipher)
      .set("anna", RuntimePassword.from("anna-passwort1"));
    const before = await storedHash(fixture.database);

    await new RotateRuntimeMasterKey(new FileRuntimeKeyRepository(fixture.keyFile),
      new LocalRuntimeSecretRotationStore(fixture.database, fixture.root)).execute(true);

    const after = await storedHash(fixture.database);
    assert.notEqual(after.masterKeyId, before.masterKeyId);
    assert.deepEqual(after.payload, before.payload, "nur der Datenschlüssel wird neu verpackt");
    const rotatedCipher = new EnvelopeRuntimeFieldCipher(await readFile(fixture.keyFile, "utf8"));
    const passwords = new SQLitePasswordCredentialRepository(fixture.database, rotatedCipher);
    assert.equal(await passwords.verify("anna", "anna-passwort1"), true);
  } finally {
    await fixture.cleanup();
  }
});

async function storedHash(database: Awaited<ReturnType<typeof rotationFixture>>["database"]) {
  const [row] = await database.all<{encrypted_hash: string}>(sql`SELECT encrypted_hash FROM runtime_password_credentials`);
  return JSON.parse(row.encrypted_hash) as {masterKeyId: string; payload: unknown};
}
