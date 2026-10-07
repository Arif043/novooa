import {sql} from "drizzle-orm";
import {files} from "../../../../db/schema.js";
import {folderTeamOf} from "./local-folder-team.js";

/** Nur Wurzeldateien besitzen eine Teamzuordnung; abgelegte Dateien erben sie vom Ordner. */
export const fileTeamId = sql<string>`coalesce(${files.root_team_id}, ${folderTeamOf(files.folder_id)})`;

export function fileLocation(teamId: string, folderId: string | null) {
  return {root_team_id: folderId === null ? teamId : null, folder_id: folderId};
}
