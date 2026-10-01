import {type FileFolders, type FileVersions} from "../../../../db/schema.js";

export type FileRow = {
  content_type: string;
  created_at: string;
  current_version_created_at: string;
  current_version_id: string | null;
  display_name: string;
  folder_id: string | null;
  id: string;
  owner_uid: string;
  size_bytes: number;
  storage_path: string;
  team_id: string;
  updated_at: string;
};

type FolderRow = Pick<FileFolders, "created_at" | "id" | "name" | "owner_uid" | "parent_folder_id" | "team_id" | "updated_at">;

type VersionRow = Pick<FileVersions, "content_type" | "created_at" | "created_by_uid" | "display_name" | "file_id" | "id" | "size_bytes" | "storage_path" | "team_id">;

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

function iso(value: string): string {
  return value.includes("T") ? value : `${value.replace(" ", "T")}Z`;
}
