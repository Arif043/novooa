export type FileEventType = "fileCreated" | "fileVersionCreated" | "fileDeleted";

/**
 * Ein fachliches Ereignis im Team-Dateibereich. `versionId` ist beim Löschen
 * `null`; die übrigen Felder beschreiben den Stand der Datei zum Zeitpunkt
 * des Ereignisses (bei `fileDeleted`: unmittelbar vor dem Löschen).
 */
export type FileEvent = {
  type: FileEventType;
  teamId: string;
  fileId: string;
  versionId: string | null;
  displayName: string;
  contentType: string;
  sizeBytes: number;
  folderId: string | null;
  occurredAt: string;
};
