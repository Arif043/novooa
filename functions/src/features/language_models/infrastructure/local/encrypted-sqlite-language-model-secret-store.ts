import {eq} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {languageModelSecrets} from "../../../../db/schema.js";
import {type SensitiveFieldCipher} from "../../../runtime_security/domain/repositories/runtime-field-cipher.js";
import {languageModelSecretContext} from "../../../runtime_security/infrastructure/runtime-secret-context.js";
import {type TransactionalLanguageModelSecretStore} from "./local-language-model-secret-store.js";

export class EncryptedSQLiteLanguageModelSecretStore implements TransactionalLanguageModelSecretStore {
  constructor(
    private readonly database: RuntimeExecutor,
    private readonly cipher: SensitiveFieldCipher,
  ) {}

  withDatabase(database: RuntimeExecutor): EncryptedSQLiteLanguageModelSecretStore {
    return new EncryptedSQLiteLanguageModelSecretStore(database, this.cipher);
  }

  async read(secretRef: string): Promise<string | null> {
    const secret = await this.database.select({encrypted_value: languageModelSecrets.encrypted_value}).from(languageModelSecrets)
      .where(eq(languageModelSecrets.secret_ref, secretRef)).get();
    return secret ? this.cipher.decrypt(secret.encrypted_value, languageModelSecretContext(secretRef)) : null;
  }

  async write(secretRef: string, value: string): Promise<void> {
    await this.database.transaction(async (tx) => {
      const encrypted_value = this.cipher.encrypt(value, languageModelSecretContext(secretRef));
      await tx.insert(languageModelSecrets).values({secret_ref: secretRef, encrypted_value})
        .onConflictDoUpdate({target: languageModelSecrets.secret_ref, set: {encrypted_value}});
    });
  }

  async delete(secretRef: string): Promise<void> {
    await this.database.delete(languageModelSecrets).where(eq(languageModelSecrets.secret_ref, secretRef));
  }
}
