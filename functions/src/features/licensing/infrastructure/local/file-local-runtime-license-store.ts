import {mkdir, readFile, rename, writeFile} from "node:fs/promises";
import {dirname, join} from "node:path";
import {type SignedRuntimeLicense} from "../../domain/entities/runtime-license-lease.js";

export type StoredRuntimeLicenseState = {
  license: SignedRuntimeLicense;
};

export interface RuntimeLicenseStore {
  load(): Promise<StoredRuntimeLicenseState | null>;
  save(state: StoredRuntimeLicenseState): Promise<void>;
}

export class FileRuntimeLicenseStore implements RuntimeLicenseStore {
  private readonly path: string;

  constructor(runtimeRoot: string) {
    this.path = join(runtimeRoot, "credentials", "license-state.json");
  }

  async load(): Promise<StoredRuntimeLicenseState | null> {
    try {
      return stateFromJson(await readFile(this.path, "utf8"));
    } catch (error) {
      if (isMissingFile(error)) return null;
      throw error;
    }
  }

  async save(state: StoredRuntimeLicenseState): Promise<void> {
    await mkdir(dirname(this.path), {recursive: true, mode: 0o700});
    const temporaryPath = `${this.path}.new`;
    await writeFile(temporaryPath, JSON.stringify(state), {encoding: "utf8", mode: 0o600});
    await rename(temporaryPath, this.path);
  }
}

function stateFromJson(value: string): StoredRuntimeLicenseState {
  const parsed = record(JSON.parse(value));
  const license = record(parsed.license);
  const payload = record(license.payload);
  return {
    license: {
      signature: requiredString(license.signature),
      payload: {
        licenseId: requiredString(payload.licenseId),
        workspaceId: requiredString(payload.workspaceId),
        issuedAt: requiredString(payload.issuedAt),
        expiresAt: optionalString(payload.expiresAt),
      },
    },
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

function optionalString(value: unknown): string | undefined {
  if (value === undefined || value === null) return undefined;
  return requiredString(value);
}
