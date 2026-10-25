import {randomUUID} from "node:crypto";
import {type GoogleAccessTokens} from "../../../google_accounts/domain/repositories/google-access-tokens.js";
import {GoogleDriveError} from "../domain/google-drive-error.js";
import {
  type GoogleDriveDownload,
  type GoogleDriveFile,
  type GoogleDriveFiles,
  type GoogleDriveUpload,
} from "../domain/google-drive-file.js";
import {exportFormatFor, isGoogleAppsType} from "./google-drive-export-formats.js";

const api = "https://www.googleapis.com/drive/v3";
const uploadApi = "https://www.googleapis.com/upload/drive/v3";
const fileFields = "id,name,mimeType,webViewLink,size";
const timeoutMilliseconds = 60_000;

/** Ruft die Drive-API direkt aus der Runtime auf; Dateiinhalte laufen nie über Firebase. */
export class GoogleDriveClient implements GoogleDriveFiles {
  constructor(
    private readonly tokens: GoogleAccessTokens,
    private readonly accountId: string,
    private readonly request: typeof fetch = fetch,
  ) {}

  async upload(file: GoogleDriveUpload): Promise<GoogleDriveFile> {
    const boundary = `novooa-${randomUUID()}`;
    const metadata = {name: file.name, mimeType: file.mimeType, ...(file.folderId ? {parents: [file.folderId]} : {})};
    const response = await this.send(`${uploadApi}/files?uploadType=multipart&supportsAllDrives=true&fields=${fileFields}`, {
      method: "POST",
      headers: {"content-type": `multipart/related; boundary=${boundary}`},
      body: multipartBody(boundary, metadata, file),
    });
    return driveFileFrom(await response.json() as Record<string, unknown>);
  }

  async download(fileId: string): Promise<GoogleDriveDownload> {
    const id = encodeURIComponent(fileId);
    const metadata = await (await this.send(`${api}/files/${id}?supportsAllDrives=true&fields=name,mimeType`)).json() as Record<string, unknown>;
    const name = typeof metadata.name === "string" ? metadata.name : fileId;
    const mimeType = typeof metadata.mimeType === "string" ? metadata.mimeType : "application/octet-stream";
    if (!isGoogleAppsType(mimeType)) {
      return {name, mimeType, content: await this.bytes(`${api}/files/${id}?alt=media&supportsAllDrives=true`)};
    }
    const format = exportFormatFor(mimeType);
    if (format === undefined) throw new GoogleDriveError(`„${name}“ ist ein Google-Format, das sich nicht als Datei lesen lässt.`);
    const content = await this.bytes(`${api}/files/${id}/export?mimeType=${encodeURIComponent(format.mimeType)}`);
    return {name: `${name}.${format.extension}`, mimeType: format.mimeType, content};
  }

  private async bytes(url: string): Promise<Uint8Array> {
    return new Uint8Array(await (await this.send(url)).arrayBuffer());
  }

  /** Lehnt Google das Token ab, wird einmal mit einem frischen wiederholt (es kann serverseitig widerrufen sein). */
  private async send(url: string, init: RequestInit = {}): Promise<Response> {
    let response = await this.authorized(url, init);
    if (response.status === 401) {
      this.tokens.invalidate(this.accountId);
      response = await this.authorized(url, init);
    }
    if (!response.ok) throw await failureFrom(response);
    return response;
  }

  private async authorized(url: string, init: RequestInit): Promise<Response> {
    const token = await this.tokens.token(this.accountId);
    const headers = {...init.headers as Record<string, string> | undefined, authorization: `Bearer ${token}`};
    return this.request(url, {...init, headers, signal: AbortSignal.timeout(timeoutMilliseconds)});
  }
}

function multipartBody(boundary: string, metadata: object, file: GoogleDriveUpload): Uint8Array<ArrayBuffer> {
  const content = typeof file.content === "string" ? Buffer.from(file.content, "utf8") : Buffer.from(file.content);
  return Uint8Array.from(Buffer.concat([
    Buffer.from(`--${boundary}\r\ncontent-type: application/json; charset=UTF-8\r\n\r\n${JSON.stringify(metadata)}\r\n`),
    Buffer.from(`--${boundary}\r\ncontent-type: ${file.mimeType}\r\n\r\n`),
    content,
    Buffer.from(`\r\n--${boundary}--`),
  ]));
}

function driveFileFrom(data: Record<string, unknown>): GoogleDriveFile {
  if (typeof data.id !== "string") throw new GoogleDriveError("Google Drive hat keine Datei zurückgegeben.");
  return {
    id: data.id,
    name: typeof data.name === "string" ? data.name : "",
    mimeType: typeof data.mimeType === "string" ? data.mimeType : "",
    webViewLink: typeof data.webViewLink === "string" ? data.webViewLink : `https://drive.google.com/file/d/${data.id}/view`,
    sizeBytes: Number(data.size ?? 0) || 0,
  };
}

/** 404 heißt bei `drive.file` meist „nicht freigegeben“; bei allem anderen zählt Googles eigener Grund. */
async function failureFrom(response: Response): Promise<GoogleDriveError> {
  const body = await response.json().catch(() => ({})) as {error?: {message?: unknown; errors?: {reason?: unknown}[]}};
  if (response.status === 404) {
    return new GoogleDriveError("Die Datei oder der Ordner wurde nicht gefunden oder ist für novooa nicht freigegeben. " +
      "Gib sie in den Einstellungen unter „Verbindungen“ über „Weitere Dateien freigeben“ frei.");
  }
  if (body.error?.errors?.some((error) => error.reason === "storageQuotaExceeded")) {
    return new GoogleDriveError("Der Google-Drive-Speicher dieses Kontos ist voll. Gib Speicher frei oder erweitere ihn.");
  }
  const reason = typeof body.error?.message === "string" ? body.error.message.slice(0, 300).replace(/\.+$/, "") : "";
  return new GoogleDriveError(`Google Drive hat die Anfrage abgelehnt (Status ${response.status})${reason ? `: ${reason}` : ""}.`);
}
