import {type FileContent} from "../../../files/domain/repositories/team-file-store.js";
import {type TeamFileContentReader} from "../../../files/domain/repositories/team-file-content-reader.js";
import {imageExtensionFor} from "./image-content-type.js";
import {isWorkflowTable} from "./workflow-table.js";
import {xlsxBufferFor} from "../../infrastructure/xlsx/xlsx-buffer.js";

export const xlsxContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

/** Inhalt eines Workflow-Werts als Datei; `sourceContentType` fehlt bei reinem Text. */
export type WorkflowValueContent = {
  content: FileContent;
  sourceContentType?: string;
};

/**
 * Macht aus einem Workflow-Wert Dateiinhalt: Team-Dateien und Bilder als Bytes ihrer Version, Tabellen als
 * XLSX, alles andere als Text (Objekte als JSON). Genutzt von allen Bausteinen, die Dateien ablegen.
 */
export async function workflowValueContent(
  value: unknown,
  files: {teamId: string; reader: TeamFileContentReader},
): Promise<WorkflowValueContent> {
  if (isFileReference(value)) {
    const file = await files.reader.readTeamFileContent(files.teamId, value.fileId, value.versionId);
    return {content: file.content, sourceContentType: file.contentType};
  }
  if (isWorkflowTable(value)) return {content: await xlsxBufferFor(value), sourceContentType: xlsxContentType};
  return {content: textFrom(value)};
}

/** Passt die Endung an, wenn der Inhalt seinen eigenen Typ mitbringt (Bild, Tabelle als XLSX). */
export function fileNameForContentType(fileName: string, contentType: string): string {
  const baseName = fileName.replace(/\.[^.]+$/, "");
  if (contentType.startsWith("image/")) return `${baseName || "bild"}.${imageExtensionFor(contentType)}`;
  if (contentType === xlsxContentType) return `${baseName || "tabelle"}.xlsx`;
  return fileName;
}

function textFrom(value: unknown): string {
  if (value === undefined || value === null) return "";
  if (typeof value === "string") return value;
  return typeof value === "number" || typeof value === "boolean" ? String(value) : JSON.stringify(value);
}

function isFileReference(value: unknown): value is {fileId: string; versionId: string} {
  if (typeof value !== "object" || value === null) return false;
  const reference = value as Record<string, unknown>;
  return typeof reference.fileId === "string" && typeof reference.versionId === "string";
}
