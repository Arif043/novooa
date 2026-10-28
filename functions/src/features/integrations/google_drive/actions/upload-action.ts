import {type NodeOutputValue} from "../../../task_execution/domain/entities/task.js";
import {
  fileNameForContentType,
  workflowValueContent,
} from "../../../task_execution/domain/services/workflow-value-content.js";
import {type GoogleDriveAction, textParam} from "../domain/google-drive-action.js";
import {GoogleDriveError} from "../domain/google-drive-error.js";

/**
 * „In Google Drive speichern“: legt den Wert als neue Datei an — Text als Textdatei, Team-Dateien und Bilder
 * mit ihren Bytes, Tabellen als XLSX. Ziel ist ein freigegebener Ordner oder „Meine Ablage“.
 */
export const uploadAction: GoogleDriveAction = {
  id: "upload",
  async execute({drive, teamId, params, resolveText, resolveValue, files}) {
    const name = resolveText(textParam(params, "fileName")).trim();
    if (name.length === 0) throw new GoogleDriveError("Bitte gib einen Dateinamen an.");
    const source = await workflowValueContent(resolveValue(textParam(params, "content")), {teamId, reader: files.reader});
    const mimeType = source.sourceContentType ?? (textParam(params, "contentType") || "text/plain");
    const file = await drive.upload({
      name: source.sourceContentType ? fileNameForContentType(name, source.sourceContentType) : name,
      mimeType, content: source.content, folderId: textParam(params, "folderId") || undefined,
    });
    return {
      value: {type: "string", value: file.webViewLink},
      driveFileId: {type: "string", value: file.id},
      name: {type: "string", value: file.name},
      mimeType: {type: "string", value: file.mimeType},
      sizeBytes: {type: "number", value: file.sizeBytes},
    } satisfies Record<string, NodeOutputValue>;
  },
  effectLabel: (outputs) => outputs.name?.type === "string" ? outputs.name.value : undefined,
};
