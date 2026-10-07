import {sql, type SQLWrapper} from "drizzle-orm";
import {fileFolders} from "../../../../db/schema.js";

/** Die einzige Teamzuordnung eines Ordnerbaums liegt an seiner Wurzel. */
export function folderTeamOf(folderId: SQLWrapper) {
  return sql<string>`(WITH RECURSIVE ancestors(id, parent, root_team) AS (
    SELECT ancestor.id, ancestor.parent_folder_id, ancestor.root_team_id
    FROM file_folders AS ancestor WHERE ancestor.id = ${folderId}
    UNION
    SELECT ancestor.id, ancestor.parent_folder_id, ancestor.root_team_id
    FROM file_folders AS ancestor JOIN ancestors ON ancestor.id = ancestors.parent
  ) SELECT root_team FROM ancestors WHERE root_team IS NOT NULL)`;
}

export const folderTeamId = folderTeamOf(fileFolders.id);

export function folderLocation(teamId: string, parentFolderId: string | null) {
  return {root_team_id: parentFolderId === null ? teamId : null, parent_folder_id: parentFolderId};
}
