export type RuntimeLicense = {
  licenseId: string;
  licenseName: string;
  activationId: string;
  workspaceId: string;
  issuedAt: string;
  expiresAt?: string;
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
    expiresAt: license.expiresAt ?? null,
  });
}

export function isActiveRuntimeLicense(license: RuntimeLicense, now: Date): boolean {
  const issuedAt = Date.parse(license.issuedAt);
  const expiresAt = license.expiresAt === undefined ? undefined : Date.parse(license.expiresAt);
  return hasRequiredValues(license) && Number.isFinite(issuedAt) &&
    issuedAt <= now.getTime() &&
    (expiresAt === undefined || (Number.isFinite(expiresAt) && expiresAt > now.getTime()));
}

function hasRequiredValues(license: RuntimeLicense): boolean {
  return [license.licenseId, license.licenseName, license.activationId, license.workspaceId]
    .every((value) => value.trim().length > 0 && value.length <= 200);
}
