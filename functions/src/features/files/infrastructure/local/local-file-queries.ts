import {and, eq, getTableColumns} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {files, fileVersions} from "../../../../db/schema.js";

/** Fachliche Dateiansicht; Versionsmetadaten werden ausschließlich aus der Version gelesen. */
export function currentFilesQuery(database: RuntimeExecutor) {
  return database.select({...getTableColumns(files),
    content_type: fileVersions.content_type, size_bytes: fileVersions.size_bytes,
    storage_path: fileVersions.storage_path, current_version_created_at: fileVersions.created_at,
  }).from(files).innerJoin(fileVersions, and(
    eq(fileVersions.file_id, files.id), eq(fileVersions.id, files.current_version_id),
  ));
}

/** Die Teamzuordnung einer Version wird über ihre Datei aufgelöst. */
export function fileVersionsQuery(database: RuntimeExecutor) {
  return database.select({...getTableColumns(fileVersions), team_id: files.team_id})
    .from(fileVersions).innerJoin(files, eq(fileVersions.file_id, files.id));
}
