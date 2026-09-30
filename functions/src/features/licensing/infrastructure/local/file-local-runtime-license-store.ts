import {readFile, rm} from "node:fs/promises";
import {join} from "node:path";
import {writeDurableSecretFile} from "../../../runtime_security/infrastructure/durable-secret-file.js";
import {type RuntimeLicenseActivation} from "../../domain/entities/runtime-license-activation.js";
import {type SensitiveFieldCipher} from "../../../runtime_security/domain/repositories/runtime-field-cipher.js";
import {licenseSecretContext} from "../../../runtime_security/infrastructure/runtime-secret-context.js";
import {RuntimeSecretFileAccess} from "../../../runtime_security/infrastructure/runtime-secret-file-access.js";

export interface RuntimeLicenseStore {
  load(): Promise<RuntimeLicenseActivation | null>;
  save(state: RuntimeLicenseActivation): Promise<void>;
  clear(): Promise<void>;
}

export class FileRuntimeLicenseStore implements RuntimeLicenseStore {
  private readonly path: string;

  constructor(
    runtimeRoot: string,
    private readonly cipher: SensitiveFieldCipher,
    private readonly access = new RuntimeSecretFileAccess(),
  ) {
    this.path = join(runtimeRoot, "credentials", "license-state.json");
  }

  async load(): Promise<RuntimeLicenseActivation | null> {
    return this.access.run(() => this.loadUnlocked());
  }

  private async loadUnlocked(): Promise<RuntimeLicenseActivation | null> {
    try {
      return stateFromJson(await readFile(this.path, "utf8"), this.cipher);
    } catch (error) {
      if (isMissingFile(error)) return null;
      if (error instanceof StoredRuntimeLicenseStateError) {
        await rm(this.path, {force: true});
        return null;
      }
      throw error;
    }
  }

  async save(state: RuntimeLicenseActivation): Promise<void> {
    await this.access.run(() => this.saveUnlocked(state));
  }

  private async saveUnlocked(state: RuntimeLicenseActivation): Promise<void> {
    const value = JSON.stringify({
      license: state.license,
      encryptedActivationSecret: this.cipher.encrypt(
        state.activationSecret, licenseSecretContext({...state.license.payload}),
      ),
    });
    await writeDurableSecretFile(this.path, value);
  }

  async clear(): Promise<void> {
    await this.access.run(() => rm(this.path, {force: true}));
  }
}

class StoredRuntimeLicenseStateError extends Error {}

function stateFromJson(value: string, cipher: SensitiveFieldCipher): RuntimeLicenseActivation {
  const state = validatedState(value);
  return {
    license: state.license,
    activationSecret: cipher.decrypt(state.encryptedActivationSecret, licenseSecretContext({...state.license.payload})),
  };
}

function validatedState(value: string): {license: RuntimeLicenseActivation["license"]; encryptedActivationSecret: string} {
  try {
    const parsed = record(JSON.parse(value));
    const license = record(parsed.license);
    const payload = record(license.payload);
    return {
      encryptedActivationSecret: requiredString(parsed.encryptedActivationSecret),
      license: {signature: requiredString(license.signature), payload: licensePayload(payload)},
    };
  } catch {
    throw new StoredRuntimeLicenseStateError();
  }
}

function licensePayload(payload: Record<string, unknown>): RuntimeLicenseActivation["license"]["payload"] {
  return {
    licenseId: requiredString(payload.licenseId), licenseName: requiredString(payload.licenseName),
    activationId: requiredString(payload.activationId), workspaceId: requiredString(payload.workspaceId),
    issuedAt: requiredString(payload.issuedAt), expiresAt: requiredString(payload.expiresAt),
  };
}

function isMissingFile(error: unknown): boolean {
  return error instanceof Error && "code" in error && error.code === "ENOENT";
}

function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  throw new Error("Der lokale Lizenzstatus ist ungültig.");
}

function requiredString(value: unknown): string {
  if (typeof value === "string" && value.trim().length > 0 && value.length <= 4000) return value;
  throw new Error("Der lokale Lizenzstatus ist ungültig.");
}
