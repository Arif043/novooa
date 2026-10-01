import {and, eq, gt} from "drizzle-orm";
import {readFile} from "node:fs/promises";
import {join} from "node:path";
import {type RuntimeExecutor} from "../../../db/database.js";
import {languageModelSecrets, type LanguageModelSecrets} from "../../../db/schema.js";
import {type RuntimeFieldCipher} from "../domain/repositories/runtime-field-cipher.js";
import {type RuntimeSecretRotationStore} from "../domain/repositories/runtime-secret-rotation-store.js";
import {writeDurableSecretFile} from "./durable-secret-file.js";
import {languageModelSecretContext, licenseSecretContext} from "./runtime-secret-context.js";
import {RuntimeSecretFileAccess} from "./runtime-secret-file-access.js";

type SecretRow = Pick<LanguageModelSecrets, "secret_ref" | "encrypted_value">;
type LicenseDocument = {license: {payload: Record<string, unknown>}; encryptedActivationSecret: string};

export class LocalRuntimeSecretRotationStore implements RuntimeSecretRotationStore {
  constructor(
    private readonly database: RuntimeExecutor,
    private readonly runtimeRoot: string,
    private readonly licenseAccess = new RuntimeSecretFileAccess(),
  ) {}

  async rewrapSecrets(cipher: RuntimeFieldCipher): Promise<number> {
    let count = 0;
    await this.forEachSecret(async (row) => {
      const encrypted = cipher.rewrap(row.encrypted_value, languageModelSecretContext(row.secret_ref));
      if (encrypted === row.encrypted_value) return;
      await this.database.update(languageModelSecrets).set({encrypted_value: encrypted}).where(and(eq(languageModelSecrets.secret_ref, row.secret_ref), eq(languageModelSecrets.encrypted_value, row.encrypted_value)));
      count++;
    });
    return count + await this.licenseAccess.run(() => this.rewrapLicense(cipher));
  }

  async verifySecrets(cipher: RuntimeFieldCipher): Promise<void> {
    await this.forEachSecret(async (row) => {
      verify(cipher, row.encrypted_value, languageModelSecretContext(row.secret_ref));
    });
    await this.licenseAccess.run(async () => {
      const document = await this.licenseDocument();
      if (document) verify(cipher, document.encryptedActivationSecret, licenseSecretContext(document.license.payload));
    });
  }

  private async rewrapLicense(cipher: RuntimeFieldCipher): Promise<number> {
    const document = await this.licenseDocument();
    if (!document) return 0;
    const encrypted = cipher.rewrap(document.encryptedActivationSecret, licenseSecretContext(document.license.payload));
    if (encrypted === document.encryptedActivationSecret) return 0;
    await writeDurableSecretFile(this.licensePath(), JSON.stringify({
      ...document, encryptedActivationSecret: encrypted,
    }));
    return 1;
  }

  private async forEachSecret(operation: (row: SecretRow) => Promise<void>): Promise<void> {
    let cursor: string | null = null;
    while (true) {
      const rows: SecretRow[] = await this.database.select({secret_ref: languageModelSecrets.secret_ref, encrypted_value: languageModelSecrets.encrypted_value})
        .from(languageModelSecrets).where(cursor === null ? undefined : gt(languageModelSecrets.secret_ref, cursor))
        .orderBy(languageModelSecrets.secret_ref).limit(100);
      if (rows.length === 0) return;
      for (const row of rows) await operation(row);
      cursor = rows[rows.length - 1].secret_ref;
    }
  }

  private async licenseDocument(): Promise<LicenseDocument | null> {
    try {
      const document = JSON.parse(await readFile(this.licensePath(), "utf8")) as LicenseDocument;
      if (typeof document.encryptedActivationSecret !== "string") throw new Error("Ungültiger Lizenzstatus.");
      licenseSecretContext(document.license.payload);
      return document;
    } catch (error) {
      if (error instanceof Error && "code" in error && error.code === "ENOENT") return null;
      throw error;
    }
  }

  private licensePath(): string {
    return join(this.runtimeRoot, "credentials", "license-state.json");
  }
}

function verify(cipher: RuntimeFieldCipher, encrypted: string, context: readonly string[]): void {
  if (!cipher.usesActiveKey(encrypted)) throw new Error("Rotation unvollständig: alter Master-Key in Verwendung.");
  cipher.decrypt(encrypted, context);
}
