import {type SqlRow} from "../../../../shared/local/local-sql-database.js";

export type FileRow = SqlRow & {
  content_type: string;
  created_at: string;
  current_version_created_at: string;
  current_version_id: string;
  display_name: string;
  folder_id: string | null;
  id: string;
  owner_uid: string;
  size_bytes: number;
  storage_path: string;
  team_id: string;
  updated_at: string;
};

export type FolderRow = SqlRow & {
  created_at: string;
  id: string;
  name: string;
  owner_uid: string;
  parent_folder_id: string | null;
  team_id: string;
  updated_at: string;
};

export type VersionRow = SqlRow & {
  content_type: string;
  created_at: string;
  created_by_uid: string;
  display_name: string;
  file_id: string;
  id: string;
  size_bytes: number;
  storage_path: string;
  team_id: string;
};

export function filesSql(): string {
  return `${fileSelectSql()} WHERE files.team_id = ? ORDER BY files.updated_at DESC`;
}

export function fileByIdSql(): string {
  return `${fileSelectSql()} WHERE files.team_id = ? AND files.id = ?`;
}

export function foldersSql(): string {
  return `SELECT id, team_id, owner_uid, name, parent_folder_id, created_at, updated_at
    FROM file_folders WHERE team_id = ? ORDER BY name COLLATE NOCASE`;
}

export function folderByIdSql(): string {
  return `SELECT id, team_id, owner_uid, name, parent_folder_id, created_at, updated_at
    FROM file_folders WHERE team_id = ? AND id = ?`;
}

export function insertFolderSql(): string {
  return "INSERT INTO file_folders(id, team_id, owner_uid, name, parent_folder_id) VALUES (?, ?, ?, ?, ?)";
}

export function versionsSql(): string {
  return `SELECT id, file_id, team_id, created_by_uid, display_name, storage_path, content_type,
    size_bytes, created_at FROM file_versions WHERE team_id = ? AND file_id = ? ORDER BY created_at DESC`;
}

export function fileFromRow(row: FileRow): Record<string, unknown> {
  return {
    id: row.id, teamId: row.team_id, ownerUid: row.owner_uid, displayName: row.display_name,
    folderId: row.folder_id, currentVersionId: row.current_version_id, contentType: row.content_type,
    sizeBytes: row.size_bytes, storagePath: row.storage_path, createdAt: iso(row.created_at),
    updatedAt: iso(row.updated_at), currentVersionCreatedAt: iso(row.current_version_created_at),
  };
}

export function folderFromRow(row: FolderRow): Record<string, unknown> {
  return {
    id: row.id, teamId: row.team_id, ownerUid: row.owner_uid, name: row.name,
    parentFolderId: row.parent_folder_id, createdAt: iso(row.created_at), updatedAt: iso(row.updated_at),
  };
}

export function versionFromRow(row: VersionRow): Record<string, unknown> {
  return {
    id: row.id, fileId: row.file_id, teamId: row.team_id, createdByUid: row.created_by_uid,
    displayName: row.display_name, storagePath: row.storage_path, contentType: row.content_type,
    sizeBytes: row.size_bytes, createdAt: iso(row.created_at),
  };
}

function fileSelectSql(): string {
  return `SELECT files.id, files.team_id, files.owner_uid, files.display_name, files.folder_id,
    files.current_version_id, files.content_type, files.size_bytes, files.storage_path,
    files.created_at, files.updated_at, versions.created_at AS current_version_created_at
    FROM files JOIN file_versions AS versions ON versions.id = files.current_version_id`;
}

function iso(value: string): string {
  return value.includes("T") ? value : `${value.replace(" ", "T")}Z`;
}
