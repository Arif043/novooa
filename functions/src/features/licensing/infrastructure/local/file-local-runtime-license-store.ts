import {mkdir, readFile, rename, rm, writeFile} from "node:fs/promises";
import {dirname, join} from "node:path";
import {type RuntimeLicenseActivation} from "../../domain/entities/runtime-license-activation.js";
import {CredentialCipher} from "../../../communication/infrastructure/security/credential-cipher.js";

export interface RuntimeLicenseStore {
  load(): Promise<RuntimeLicenseActivation | null>;
  save(state: RuntimeLicenseActivation): Promise<void>;
  clear(): Promise<void>;
}

export class FileRuntimeLicenseStore implements RuntimeLicenseStore {
  private readonly path: string;

  constructor(runtimeRoot: string, private readonly cipher: CredentialCipher) {
    this.path = join(runtimeRoot, "credentials", "license-state.json");
  }

  async load(): Promise<RuntimeLicenseActivation | null> {
    try {
      return stateFromJson(await readFile(this.path, "utf8"), this.cipher);
    } catch (error) {
      if (isMissingFile(error)) return null;
      if (error instanceof StoredRuntimeLicenseStateError) {
        await this.clear();
        return null;
      }
      throw error;
    }
  }

  async save(state: RuntimeLicenseActivation): Promise<void> {
    await mkdir(dirname(this.path), {recursive: true, mode: 0o700});
    const temporaryPath = this.path + ".new";
    const value = JSON.stringify({
      license: state.license,
      encryptedActivationSecret: this.cipher.encrypt(state.activationSecret),
    });
    await writeFile(temporaryPath, value, {encoding: "utf8", mode: 0o600});
    await rename(temporaryPath, this.path);
  }

  async clear(): Promise<void> {
    await rm(this.path, {force: true});
  }
}

class StoredRuntimeLicenseStateError extends Error {}

function stateFromJson(value: string, cipher: CredentialCipher): RuntimeLicenseActivation {
  try {
    const parsed = record(JSON.parse(value));
    const license = record(parsed.license);
    const payload = record(license.payload);
    return {
      activationSecret: cipher.decrypt(requiredString(parsed.encryptedActivationSecret)),
      license: {
        signature: requiredString(license.signature),
        payload: {
          licenseId: requiredString(payload.licenseId),
          licenseName: requiredString(payload.licenseName),
          activationId: requiredString(payload.activationId),
          workspaceId: requiredString(payload.workspaceId),
          issuedAt: requiredString(payload.issuedAt),
          expiresAt: requiredString(payload.expiresAt),
        },
      },
    };
  } catch {
    throw new StoredRuntimeLicenseStateError();
  }
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
