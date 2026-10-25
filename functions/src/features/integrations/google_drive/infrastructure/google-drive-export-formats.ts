/** Google-eigene Formate haben keinen Dateiinhalt; sie werden in ein gängiges Format exportiert. */
const exportFormats: Record<string, {mimeType: string; extension: string}> = {
  "application/vnd.google-apps.document": {mimeType: "application/pdf", extension: "pdf"},
  "application/vnd.google-apps.presentation": {mimeType: "application/pdf", extension: "pdf"},
  "application/vnd.google-apps.drawing": {mimeType: "application/pdf", extension: "pdf"},
  "application/vnd.google-apps.spreadsheet": {
    mimeType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", extension: "xlsx",
  },
};

export function exportFormatFor(mimeType: string): {mimeType: string; extension: string} | undefined {
  return exportFormats[mimeType];
}

export function isGoogleAppsType(mimeType: string): boolean {
  return mimeType.startsWith("application/vnd.google-apps.");
}
