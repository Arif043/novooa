export type RuntimeLicense = {
  licenseId: string;
  licenseName: string;
  activationId: string;
  workspaceId: string;
  issuedAt: string;
  expiresAt: string;
  /** Wie viele Konten die Runtime haben darf; `null` = unbegrenzt. */
  maxUsers: number | null;
};

export type SignedRuntimeLicense = {
  payload: RuntimeLicense;
  signature: string;
};

export function runtimeLicensePayloadJson(license: RuntimeLicense): string {
  return JSON.stringify({
    licenseId: license.licenseId,
    licenseName: license.licenseName,
    activationId: license.activationId,
    workspaceId: license.workspaceId,
    issuedAt: license.issuedAt,
    expiresAt: license.expiresAt,
    maxUsers: license.maxUsers,
  });
}

export function isActiveRuntimeLicense(license: RuntimeLicense, now: Date): boolean {
  const issuedAt = Date.parse(license.issuedAt);
  const expiresAt = Date.parse(license.expiresAt);
  return hasRequiredValues(license) && Number.isFinite(issuedAt) &&
    issuedAt <= now.getTime() &&
    Number.isFinite(expiresAt) && expiresAt > now.getTime();
}

function hasRequiredValues(license: RuntimeLicense): boolean {
  return [license.licenseId, license.licenseName, license.activationId, license.workspaceId]
    .every((value) => value.trim().length > 0 && value.length <= 200);
}

const maximumUserLimit = 100_000;

/** Liest die Nutzerzahl einer Lizenz: eine positive ganze Zahl oder `null` (unbegrenzt); fehlt sie, ist die Lizenz ungültig. */
export function maxUsersFrom(value: unknown): number | null {
  if (value === null) return null;
  if (typeof value === "number" && Number.isInteger(value) && value > 0 && value <= maximumUserLimit) return value;
  throw new Error("maxUsers ist ungültig.");
}
