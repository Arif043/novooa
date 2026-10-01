import {eq} from "drizzle-orm";
import {readFile} from "node:fs/promises";
import {join} from "node:path";
import {type RuntimeExecutor} from "../../../db/database.js";
import {languageModelSecrets} from "../../../db/schema.js";
import {CredentialCipher} from "../../communication/infrastructure/security/credential-cipher.js";
import {writeDurableSecretFile} from "./durable-secret-file.js";
import {EnvelopeRuntimeFieldCipher} from "./envelope-runtime-field-cipher.js";
import {parseRuntimeKeyring} from "./runtime-keyring.js";
import {languageModelSecretContext, licenseSecretContext} from "./runtime-secret-context.js";

export class UpgradeRuntimeSecretFormat {
  private readonly cipher: EnvelopeRuntimeFieldCipher;
  private readonly legacyCiphers: CredentialCipher[];

  constructor(
    private readonly database: RuntimeExecutor,
    private readonly root: string,
    keyring: string,
  ) {
    this.cipher = new EnvelopeRuntimeFieldCipher(keyring);
    this.legacyCiphers = Object.values(parseRuntimeKeyring(keyring).keys).map((key) => new CredentialCipher(key));
  }

  async execute(): Promise<void> {
    await this.database.transaction((tx) => this.upgradeModelSecrets(tx));
    await this.upgradeLicenseSecret();
  }

  private async upgradeModelSecrets(database: RuntimeExecutor): Promise<void> {
    const rows = await database.select({secret_ref: languageModelSecrets.secret_ref, encrypted_value: languageModelSecrets.encrypted_value}).from(languageModelSecrets);
    for (const row of rows) {
      if (isEnvelope(row.encrypted_value)) continue;
      const encrypted = this.upgrade(row.encrypted_value, languageModelSecretContext(row.secret_ref));
      await database.update(languageModelSecrets).set({encrypted_value: encrypted}).where(eq(languageModelSecrets.secret_ref, row.secret_ref));
    }
  }

  private async upgradeLicenseSecret(): Promise<void> {
    const path = join(this.root, "credentials", "license-state.json");
    const document = await licenseDocument(path);
    if (!document || isEnvelope(document.encryptedActivationSecret)) return;
    const encryptedActivationSecret = this.upgrade(
      document.encryptedActivationSecret, licenseSecretContext(document.license.payload),
    );
    await writeDurableSecretFile(path, JSON.stringify({...document, encryptedActivationSecret}));
  }

  private upgrade(value: string, context: readonly string[]): string {
    for (const cipher of this.legacyCiphers) {
      try {
        return this.cipher.encrypt(cipher.decrypt(value), context);
      } catch {
        // Frühere Schlüssel können aus Backups stammen; nur ein passender
        // Schlüssel darf das alte Format erfolgreich authentifizieren.
      }
    }
    throw new Error("Ein vorhandenes Runtime-Geheimnis kann mit dem Schlüsselbund nicht entschlüsselt werden.");
  }
}

type LicenseDocument = {license: {payload: Record<string, unknown>}; encryptedActivationSecret: string};

async function licenseDocument(path: string): Promise<LicenseDocument | null> {
  try {
    const document = JSON.parse(await readFile(path, "utf8")) as LicenseDocument;
    if (typeof document.encryptedActivationSecret !== "string") throw new Error("Ungültiger Lizenzstatus.");
    return document;
  } catch (error) {
    if (error instanceof Error && "code" in error && error.code === "ENOENT") return null;
    throw error;
  }
}

function isEnvelope(value: string): boolean {
  return value.trim().startsWith("{");
}
