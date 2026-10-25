import {type FileContent} from "../../../files/domain/repositories/team-file-store.js";

/** Eine Datei in Google Drive, wie die Bausteine sie weitergeben. */
export type GoogleDriveFile = {
  id: string;
  name: string;
  mimeType: string;
  /** Adresse zum Öffnen im Browser. */
  webViewLink: string;
  sizeBytes: number;
};

export type GoogleDriveUpload = {
  name: string;
  mimeType: string;
  content: FileContent;
  /** Ohne Ordner landet die Datei in „Meine Ablage“. */
  folderId?: string;
};

export type GoogleDriveDownload = {
  name: string;
  mimeType: string;
  content: Uint8Array;
};

/** Zugriff auf Drive im Namen eines verbundenen Kontos. */
export interface GoogleDriveFiles {
  upload(file: GoogleDriveUpload): Promise<GoogleDriveFile>;
  /** Google-Dokumente, -Tabellen und -Präsentationen kommen als PDF bzw. XLSX. */
  download(fileId: string): Promise<GoogleDriveDownload>;
}
