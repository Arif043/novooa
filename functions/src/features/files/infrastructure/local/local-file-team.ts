import {sql} from "drizzle-orm";
import {files} from "../../../../db/schema.js";

/** Nur Wurzeldateien besitzen eine Teamzuordnung; abgelegte Dateien erben sie vom Ordner. */
export const fileTeamId = sql<string>`coalesce(${files.root_team_id},
  (SELECT folder.team_id FROM file_folders AS folder WHERE folder.id = ${files.folder_id}))`;

export function fileLocation(teamId: string, folderId: string | null) {
  return {root_team_id: folderId === null ? teamId : null, folder_id: folderId};
}
