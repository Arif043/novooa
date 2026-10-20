export type RuntimeLicenseContext = {
  licenseId: string; licenseName: string; workspaceId: string; expiresAt: string;
  /** Wie viele Konten die Runtime haben darf; `null` = unbegrenzt. */
  maxUsers: number | null;
};
