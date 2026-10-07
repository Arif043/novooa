import {z} from "zod";
import {type FileFolders, type Files, type FileVersions} from "../../../../db/schema.js";

const id = z.string().min(1).max(200);
const timestamp = z.string().min(1).max(64);
const sizeBytes = z.number().int().nonnegative();

const folderDto = z.object({
  id, ownerUid: z.string(), name: z.string().min(1), parentFolderId: id.nullable(),
  createdAt: timestamp, updatedAt: timestamp,
});

const fileDto = z.object({
  id, ownerUid: z.string(), displayName: z.string().min(1), folderId: id.nullable(),
  currentVersionId: id.nullable(),
  createdAt: timestamp, updatedAt: timestamp,
});

const versionDto = z.object({
  id, fileId: id, createdByUid: z.string(), displayName: z.string().min(1), storagePath: z.string().min(1),
  contentType: z.string(), sizeBytes, createdAt: timestamp,
});

export const filesTransferPayload = z.object({
  folders: z.array(folderDto), files: z.array(fileDto), versions: z.array(versionDto),
});

export type FilesTransferPayload = z.infer<typeof filesTransferPayload>;
export type FolderDto = z.infer<typeof folderDto>;
export type FileDto = z.infer<typeof fileDto>;
export type VersionDto = z.infer<typeof versionDto>;

export function folderDtoFrom(row: FileFolders): FolderDto {
  return {id: row.id, ownerUid: row.owner_uid, name: row.name, parentFolderId: row.parent_folder_id,
    createdAt: row.created_at, updatedAt: row.updated_at};
}

export function fileDtoFrom(row: Files): FileDto {
  return {id: row.id, ownerUid: row.owner_uid, displayName: row.display_name, folderId: row.folder_id,
    currentVersionId: row.current_version_id, createdAt: row.created_at, updatedAt: row.updated_at};
}

export function versionDtoFrom(row: FileVersions): VersionDto {
  return {id: row.id, fileId: row.file_id, createdByUid: row.created_by_uid, displayName: row.display_name,
    storagePath: row.storage_path, contentType: row.content_type, sizeBytes: row.size_bytes, createdAt: row.created_at};
}

/** Eltern vor Kindern, damit der Fremdschlüssel auf `parent_folder_id` hält. */
export function parentsFirst(folders: readonly FolderDto[]): FolderDto[] {
  const pending = new Map(folders.map((folder) => [folder.id, folder]));
  const ordered: FolderDto[] = [];
  const visit = (folder: FolderDto, path: Set<string>) => {
    if (!pending.has(folder.id) || path.has(folder.id)) return;
    const parent = folder.parentFolderId === null ? undefined : pending.get(folder.parentFolderId);
    if (parent !== undefined) visit(parent, new Set([...path, folder.id]));
    pending.delete(folder.id);
    ordered.push(folder);
  };
  for (const folder of folders) visit(folder, new Set());
  return ordered;
}
