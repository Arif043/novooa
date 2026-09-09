export type LocalRuntimeLicense = {
  licenseId: string;
  workspaceId: string;
  issuedAt: string;
  expiresAt?: string;
};

export type SignedLocalRuntimeLicense = {
  payload: LocalRuntimeLicense;
  signature: string;
};

export function localRuntimeLicensePayloadJson(
  license: LocalRuntimeLicense,
): string {
  return JSON.stringify({
    licenseId: license.licenseId,
    workspaceId: license.workspaceId,
    issuedAt: license.issuedAt,
    expiresAt: license.expiresAt ?? null,
  });
}

export function isActiveLocalRuntimeLicense(
  license: LocalRuntimeLicense,
  now: Date,
): boolean {
  const issuedAt = Date.parse(license.issuedAt);
  const expiresAt = license.expiresAt === undefined
    ? undefined
    : Date.parse(license.expiresAt);
  return hasRequiredValues(license) &&
    Number.isFinite(issuedAt) &&
    issuedAt <= now.getTime() &&
    (expiresAt === undefined || (Number.isFinite(expiresAt) && expiresAt > now.getTime()));
}

function hasRequiredValues(license: LocalRuntimeLicense): boolean {
  return [license.licenseId, license.workspaceId]
    .every((value) => value.trim().length > 0 && value.length <= 200);
}
