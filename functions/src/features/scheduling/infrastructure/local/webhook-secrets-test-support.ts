import {randomBytes} from "node:crypto";
import {type RuntimeDatabase} from "../../../../db/database.js";
import {CredentialCipher} from "../../../communication/infrastructure/security/credential-cipher.js";
import {EncryptedSQLiteLanguageModelSecretStore} from "../../../language_models/infrastructure/local/encrypted-sqlite-language-model-secret-store.js";

/** Nur Tests: echter verschlüsselter Speicher mit Wegwerf-Schlüssel. */
export function webhookSecretsFor(database: RuntimeDatabase) {
  return new EncryptedSQLiteLanguageModelSecretStore(database, new CredentialCipher(randomBytes(32).toString("base64")));
}
