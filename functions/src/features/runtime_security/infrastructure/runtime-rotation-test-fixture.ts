import {sql} from "drizzle-orm";
import {mkdtemp, readFile, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join} from "node:path";
import {connectRuntimeDatabase} from "../../../db/database.js";
import {prepareLocalRuntimeMasterKey} from "../../../shared/local/local-runtime-master-key.js";
import {EncryptedSQLiteLanguageModelSecretStore} from "../../language_models/infrastructure/local/encrypted-sqlite-language-model-secret-store.js";
import {FileRuntimeLicenseStore} from "../../licensing/infrastructure/local/file-local-runtime-license-store.js";
import {EnvelopeRuntimeFieldCipher} from "./envelope-runtime-field-cipher.js";

export async function rotationFixture() {
  const root = await mkdtemp(join(tmpdir(), "novooa-rotation-"));
  const keyFile = join(root, "secrets", "runtime-master-key");
  await prepareLocalRuntimeMasterKey(keyFile);
  const cipher = new EnvelopeRuntimeFieldCipher(await readFile(keyFile, "utf8"));
  const database = connectRuntimeDatabase(join(root, "novooa.sqlite"));
  await database.run(sql`CREATE TABLE language_model_secrets (secret_ref TEXT PRIMARY KEY, encrypted_value TEXT NOT NULL, updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)`);
  await database.run(sql`CREATE TABLE runtime_password_credentials (uid TEXT PRIMARY KEY, encrypted_hash TEXT NOT NULL, salt TEXT NOT NULL, updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)`);
  const secrets = new EncryptedSQLiteLanguageModelSecretStore(database, cipher);
  await secrets.write("model/a", "key-a");
  await secrets.write("model/b", "key-b");
  await new FileRuntimeLicenseStore(root, cipher).save(licenseActivation());
  return {root, keyFile, database, cipher, cleanup: async () => {
    database.$client.close();
    await rm(root, {recursive: true, force: true});
  }};
}

function licenseActivation() {
  return {
    activationSecret: "activation-secret",
    license: {signature: "signature", payload: {
      licenseId: "license-1", licenseName: "Example", activationId: "activation-1",
      workspaceId: "workspace-1", issuedAt: "2026-09-30T00:00:00Z", expiresAt: "2027-09-30T00:00:00Z",
      maxUsers: 5,
    }},
  };
}
