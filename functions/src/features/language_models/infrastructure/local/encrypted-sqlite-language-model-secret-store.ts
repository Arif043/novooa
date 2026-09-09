import {CredentialCipher} from "../../../communication/infrastructure/security/credential-cipher.js";
import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";
import {type LocalLanguageModelSecretStore} from "./local-language-model-secret-store.js";

type SecretRow = SqlRow & {encrypted_value: string};

export class EncryptedSQLiteLanguageModelSecretStore implements LocalLanguageModelSecretStore {
  constructor(
    private readonly database: LocalSqlDatabase,
    private readonly cipher: CredentialCipher,
  ) {}

  async read(secretRef: string): Promise<string | null> {
    const secret = await this.database.get<SecretRow>(
      "SELECT encrypted_value FROM language_model_secrets WHERE secret_ref = ?",
      [secretRef],
    );
    return secret ? this.cipher.decrypt(secret.encrypted_value) : null;
  }

  async write(secretRef: string, value: string): Promise<void> {
    await this.database.run(
      `INSERT INTO language_model_secrets (secret_ref, encrypted_value)
       VALUES (?, ?)
       ON CONFLICT(secret_ref) DO UPDATE SET encrypted_value = excluded.encrypted_value`,
      [secretRef, this.cipher.encrypt(value)],
    );
  }

  async delete(secretRef: string): Promise<void> {
    await this.database.run(
      "DELETE FROM language_model_secrets WHERE secret_ref = ?",
      [secretRef],
    );
  }
}
