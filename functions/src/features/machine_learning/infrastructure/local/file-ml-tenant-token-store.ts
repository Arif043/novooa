import {readFile, rm} from "node:fs/promises";
import {join} from "node:path";
import {type SensitiveFieldCipher} from "../../../runtime_security/domain/repositories/runtime-field-cipher.js";
import {writeDurableSecretFile} from "../../../runtime_security/infrastructure/durable-secret-file.js";
import {mlServiceTokenContext} from "../../../runtime_security/infrastructure/runtime-secret-context.js";
import {type RuntimeSecretFileAccess} from "../../../runtime_security/infrastructure/runtime-secret-file-access.js";
import {type MlTenantTokenStore, type StoredMlTenantToken} from "./ml-tenant-session.js";

export function mlTenantTokenPath(runtimeRoot: string): string {
  return join(runtimeRoot, "credentials", "ml-service-token.json");
}

/** Das Token liegt verschlüsselt neben dem Lizenzstatus; der Schlüsselwechsel verschlüsselt es mit um. */
export class FileMlTenantTokenStore implements MlTenantTokenStore {
  private readonly path: string;

  constructor(
    runtimeRoot: string,
    private readonly cipher: SensitiveFieldCipher,
    private readonly access: RuntimeSecretFileAccess,
  ) {
    this.path = mlTenantTokenPath(runtimeRoot);
  }

  load(): Promise<StoredMlTenantToken | null> {
    return this.access.run(async () => {
      const document = await this.document();
      if (document === null) return null;
      return {tenantId: document.tenantId, token: this.cipher.decrypt(document.encryptedToken, mlServiceTokenContext(document.tenantId))};
    });
  }

  save(token: StoredMlTenantToken): Promise<void> {
    return this.access.run(() => writeDurableSecretFile(this.path, JSON.stringify({
      tenantId: token.tenantId,
      encryptedToken: this.cipher.encrypt(token.token, mlServiceTokenContext(token.tenantId)),
    })));
  }

  clear(): Promise<void> {
    return this.access.run(() => rm(this.path, {force: true}));
  }

  private async document(): Promise<{tenantId: string; encryptedToken: string} | null> {
    try {
      return mlTokenDocumentFrom(await readFile(this.path, "utf8"));
    } catch (error) {
      if (error instanceof Error && "code" in error && error.code === "ENOENT") return null;
      throw error;
    }
  }
}

export function mlTokenDocumentFrom(text: string): {tenantId: string; encryptedToken: string} {
  const document = JSON.parse(text) as Record<string, unknown>;
  if (typeof document.tenantId !== "string" || typeof document.encryptedToken !== "string") {
    throw new Error("Ungültige Anmeldung beim ML-Dienst.");
  }
  return {tenantId: document.tenantId, encryptedToken: document.encryptedToken};
}
