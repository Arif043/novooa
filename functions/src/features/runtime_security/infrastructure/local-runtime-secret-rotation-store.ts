import {and, eq, gt} from "drizzle-orm";
import {readFile} from "node:fs/promises";
import {join} from "node:path";
import {type RuntimeExecutor} from "../../../db/database.js";
import {languageModelSecrets, runtimePasswordCredentials} from "../../../db/schema.js";
import {type RuntimeFieldCipher} from "../domain/repositories/runtime-field-cipher.js";
import {type RuntimeSecretRotationStore} from "../domain/repositories/runtime-secret-rotation-store.js";
import {writeDurableSecretFile} from "./durable-secret-file.js";
import {languageModelSecretContext, licenseSecretContext, mlServiceTokenContext, passwordHashContext} from "./runtime-secret-context.js";
import {RuntimeSecretFileAccess} from "./runtime-secret-file-access.js";

/** Eine Zeile mit verschlüsseltem Wert; `key` ist zugleich der Teil des Feldkontexts, der sie eindeutig macht. */
type EncryptedRow = {key: string; encrypted: string};

/** Tabellen, deren Werte mit dem Master-Key verschlüsselt sind. */
const encryptedColumns = [
  {table: languageModelSecrets, key: languageModelSecrets.secret_ref, value: languageModelSecrets.encrypted_value, context: languageModelSecretContext},
  {table: runtimePasswordCredentials, key: runtimePasswordCredentials.uid, value: runtimePasswordCredentials.encrypted_hash, context: passwordHashContext},
] as const;
type EncryptedColumn = typeof encryptedColumns[number];
type LicenseDocument = {license: {payload: Record<string, unknown>}; encryptedActivationSecret: string};
type MlTokenDocument = {tenantId: string; encryptedToken: string};

export class LocalRuntimeSecretRotationStore implements RuntimeSecretRotationStore {
  constructor(
    private readonly database: RuntimeExecutor,
    private readonly runtimeRoot: string,
    private readonly licenseAccess = new RuntimeSecretFileAccess(),
  ) {}

  async rewrapSecrets(cipher: RuntimeFieldCipher): Promise<number> {
    let count = 0;
    for (const column of encryptedColumns) {
      await this.forEachRow(column, async (row) => {
        const encrypted = cipher.rewrap(row.encrypted, column.context(row.key));
        if (encrypted === row.encrypted) return;
        await this.database.update(column.table).set({[column.value.name]: encrypted})
          .where(and(eq(column.key, row.key), eq(column.value, row.encrypted)));
        count++;
      });
    }
    return count + await this.licenseAccess.run(async () => await this.rewrapLicense(cipher) + await this.rewrapMlToken(cipher));
  }

  async verifySecrets(cipher: RuntimeFieldCipher): Promise<void> {
    for (const column of encryptedColumns) {
      await this.forEachRow(column, async (row) => verify(cipher, row.encrypted, column.context(row.key)));
    }
    await this.licenseAccess.run(async () => {
      const document = await this.licenseDocument();
      if (document) verify(cipher, document.encryptedActivationSecret, licenseSecretContext(document.license.payload));
      const token = await this.mlTokenDocument();
      if (token) verify(cipher, token.encryptedToken, mlServiceTokenContext(token.tenantId));
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

  /** Die Anmeldung beim ML-Dienst (siehe FileMlTenantTokenStore) liegt unter derselben Sperre wie der Lizenzstatus. */
  private async rewrapMlToken(cipher: RuntimeFieldCipher): Promise<number> {
    const document = await this.mlTokenDocument();
    if (!document) return 0;
    const encrypted = cipher.rewrap(document.encryptedToken, mlServiceTokenContext(document.tenantId));
    if (encrypted === document.encryptedToken) return 0;
    await writeDurableSecretFile(this.mlTokenPath(), JSON.stringify({...document, encryptedToken: encrypted}));
    return 1;
  }

  private async mlTokenDocument(): Promise<MlTokenDocument | null> {
    const text = await readOptional(this.mlTokenPath());
    if (text === null) return null;
    const document = JSON.parse(text) as MlTokenDocument;
    if (typeof document.tenantId !== "string" || typeof document.encryptedToken !== "string") {
      throw new Error("Ungültige Anmeldung beim ML-Dienst.");
    }
    return document;
  }

  private mlTokenPath(): string {
    return join(this.runtimeRoot, "credentials", "ml-service-token.json");
  }

  private async forEachRow(column: EncryptedColumn, operation: (row: EncryptedRow) => Promise<void>): Promise<void> {
    let cursor: string | null = null;
    while (true) {
      const rows: EncryptedRow[] = await this.database.select({key: column.key, encrypted: column.value})
        .from(column.table).where(cursor === null ? undefined : gt(column.key, cursor))
        .orderBy(column.key).limit(100);
      if (rows.length === 0) return;
      for (const row of rows) await operation(row);
      cursor = rows[rows.length - 1].key;
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

async function readOptional(path: string): Promise<string | null> {
  try {
    return await readFile(path, "utf8");
  } catch (error) {
    if (error instanceof Error && "code" in error && error.code === "ENOENT") return null;
    throw error;
  }
}

function verify(cipher: RuntimeFieldCipher, encrypted: string, context: readonly string[]): void {
  if (!cipher.usesActiveKey(encrypted)) throw new Error("Rotation unvollständig: alter Master-Key in Verwendung.");
  cipher.decrypt(encrypted, context);
}
