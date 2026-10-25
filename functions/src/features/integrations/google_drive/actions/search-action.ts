import {type NodeOutputValue} from "../../../task_execution/domain/entities/task.js";
import {type GoogleDriveAction, textParam} from "../domain/google-drive-action.js";
import {GoogleDriveError} from "../domain/google-drive-error.js";

export const searchLimitDefault = 25;
export const searchLimitMax = 100;

/**
 * „In Google Drive suchen“: liefert die passenden Dateien als Liste, neueste zuerst. Mit `drive.file` sind das
 * nur Dateien, die novooa angelegt hat oder die im Picker freigegeben wurden.
 */
export const searchAction: GoogleDriveAction = {
  id: "search",
  async execute({drive, params, resolveText}) {
    const files = await drive.search({
      nameContains: resolveText(textParam(params, "name")).trim() || undefined,
      folderId: textParam(params, "folderId") || undefined,
      limit: limitFrom(params.limit),
    });
    const items = files.map((file) => ({
      id: file.id, name: file.name, mimeType: file.mimeType, link: file.webViewLink,
      sizeBytes: file.sizeBytes, modifiedAt: file.modifiedAt,
    }));
    return {
      value: {type: "json", value: items},
      count: {type: "number", value: items.length},
      found: {type: "boolean", value: items.length > 0},
    } satisfies Record<string, NodeOutputValue>;
  },
};

function limitFrom(value: unknown): number {
  if (value === undefined || value === null || value === "") return searchLimitDefault;
  const limit = Number(value);
  if (!Number.isInteger(limit) || limit < 1 || limit > searchLimitMax) {
    throw new GoogleDriveError(`Die Höchstanzahl muss eine ganze Zahl zwischen 1 und ${searchLimitMax} sein.`);
  }
  return limit;
}
