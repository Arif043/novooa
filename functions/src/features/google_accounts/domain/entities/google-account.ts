/** Eine Datei oder ein Ordner, den Nutzer:innen beim Verbinden im Google-Picker freigegeben haben. */
export type GoogleDriveItem = {
  id: string;
  name: string;
  mimeType: string;
};

export const googleDriveFolderMimeType = "application/vnd.google-apps.folder";

export type GoogleAccountStatus = "active" | "reauthorizationRequired";

/**
 * Ein verbundenes Google-Konto. Es gehört genau einer Runtime-Lizenz; nur diese Runtime bekommt
 * Zugriffstokens dafür. Mit dem Scope `drive.file` sieht novooa nur `sharedItems` und selbst angelegte Dateien.
 */
export type GoogleAccount = {
  id: string;
  teamId: string;
  runtimeLicenseId: string;
  /** Feste Kennung des Google-Kontos (`sub`); die E-Mail-Adresse kann sich ändern. */
  googleUserId: string;
  email: string;
  status: GoogleAccountStatus;
  sharedItems: GoogleDriveItem[];
  createdAt: Date;
  updatedAt: Date;
};

/** Was die Runtime sieht: keine Kennungen anderer Systeme, keine Zugangsdaten. */
export type GoogleAccountSummary = Pick<GoogleAccount, "id" | "email" | "status" | "sharedItems">;

export function googleAccountSummaryFrom(account: GoogleAccount): GoogleAccountSummary {
  return {id: account.id, email: account.email, status: account.status, sharedItems: account.sharedItems};
}

/** Neue Freigaben kommen hinzu; ist ein Eintrag schon bekannt, gilt sein neuer Name. */
export function mergedSharedItems(existing: GoogleDriveItem[], added: GoogleDriveItem[]): GoogleDriveItem[] {
  const byId = new Map(existing.map((item) => [item.id, item]));
  for (const item of added) byId.set(item.id, item);
  return [...byId.values()];
}
