import {type NodeOutputValue} from "../../../task_execution/domain/entities/task.js";
import {fileOutputFor} from "../../../task_execution/domain/services/file-output-values.js";
import {type GoogleDriveAction, textParam} from "../domain/google-drive-action.js";
import {GoogleDriveError} from "../domain/google-drive-error.js";

/**
 * „Aus Google Drive lesen“: lädt eine Datei und legt sie als Team-Datei ab, damit folgende Bausteine
 * (Dokumente, Prompts mit Anhang, „Datei schreiben“) sie wie jede andere Datei nutzen.
 */
export const readAction: GoogleDriveAction = {
  id: "read",
  async execute({drive, teamId, params, resolveText, files}) {
    const fileId = resolveText(textParam(params, "fileId")).trim();
    if (fileId.length === 0) throw new GoogleDriveError("Bitte wähle eine Datei aus Google Drive.");
    const download = await drive.download(fileId);
    const stored = await files.store.writeTeamFile({
      teamId, content: download.content, fileName: download.name, contentType: download.mimeType,
      folderId: null, targetFileId: null,
    });
    return {
      value: fileOutputFor(stored),
      driveFileId: {type: "string", value: fileId},
      name: {type: "string", value: download.name},
      mimeType: {type: "string", value: download.mimeType},
    } satisfies Record<string, NodeOutputValue>;
  },
};
