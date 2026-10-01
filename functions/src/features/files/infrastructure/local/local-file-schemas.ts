import {type Static, Type} from "@fastify/type-provider-typebox";
import {type FileFolders, type FileVersions} from "../../../../db/schema.js";
import {NonEmptyString} from "../../../../shared/local/local-runtime-http-schemas.js";

const NullableString = Type.Union([Type.String(), Type.Null()]);

export const TeamFileDto = Type.Object({
  id: Type.String(), teamId: Type.String(), ownerUid: Type.String(), displayName: Type.String(),
  folderId: NullableString, currentVersionId: NullableString, contentType: Type.String(), sizeBytes: Type.Integer(),
  storagePath: Type.String(), createdAt: Type.String(), updatedAt: Type.String(), currentVersionCreatedAt: Type.String(),
});
export const FolderDto = Type.Object({
  id: Type.String(), teamId: Type.String(), ownerUid: Type.String(), name: Type.String(),
  parentFolderId: NullableString, createdAt: Type.String(), updatedAt: Type.String(),
});
export const FileVersionDto = Type.Object({
  id: Type.String(), fileId: Type.String(), teamId: Type.String(), createdByUid: Type.String(), displayName: Type.String(),
  storagePath: Type.String(), contentType: Type.String(), sizeBytes: Type.Integer(), createdAt: Type.String(),
});

/** Dateiname ohne Pfadanteile; Inhalt als Base64. */
export const FileUpload = Type.Object({
  name: Type.String({minLength: 1, maxLength: 255, pattern: "^(?!\\.{1,2}$)[^/\\\\]+$"}),
  contentBase64: Type.String({pattern: "^[A-Za-z0-9+/]*={0,2}$"}),
  contentType: Type.Optional(Type.String({maxLength: 200})),
  folderId: Type.Optional(NullableString),
});
export const NewFolder = Type.Object({
  name: Type.String({minLength: 1, maxLength: 255, pattern: "\\S"}),
  parentFolderId: Type.Optional(NullableString),
});
export const FileParams = Type.Object({fileId: NonEmptyString({maxLength: 200})});
export const VersionParams = Type.Object({fileId: NonEmptyString({maxLength: 200}), versionId: NonEmptyString({maxLength: 200})});

export type FileRow = {
  content_type: string; created_at: string; current_version_created_at: string; current_version_id: string | null;
  display_name: string; folder_id: string | null; id: string; owner_uid: string; size_bytes: number;
  storage_path: string; team_id: string; updated_at: string;
};
type FolderRow = Pick<FileFolders, "created_at" | "id" | "name" | "owner_uid" | "parent_folder_id" | "team_id" | "updated_at">;
type VersionRow = Pick<FileVersions, "content_type" | "created_at" | "created_by_uid" | "display_name" | "file_id" | "id" |
  "size_bytes" | "storage_path" | "team_id">;

export function fileFromRow(row: FileRow): Static<typeof TeamFileDto> {
  return {
    id: row.id, teamId: row.team_id, ownerUid: row.owner_uid, displayName: row.display_name,
    folderId: row.folder_id, currentVersionId: row.current_version_id, contentType: row.content_type,
    sizeBytes: row.size_bytes, storagePath: row.storage_path, createdAt: iso(row.created_at),
    updatedAt: iso(row.updated_at), currentVersionCreatedAt: iso(row.current_version_created_at),
  };
}

export function folderFromRow(row: FolderRow): Static<typeof FolderDto> {
  return {
    id: row.id, teamId: row.team_id, ownerUid: row.owner_uid, name: row.name,
    parentFolderId: row.parent_folder_id, createdAt: iso(row.created_at), updatedAt: iso(row.updated_at),
  };
}

export function versionFromRow(row: VersionRow): Static<typeof FileVersionDto> {
  return {
    id: row.id, fileId: row.file_id, teamId: row.team_id, createdByUid: row.created_by_uid,
    displayName: row.display_name, storagePath: row.storage_path, contentType: row.content_type,
    sizeBytes: row.size_bytes, createdAt: iso(row.created_at),
  };
}

function iso(value: string): string {
  return value.includes("T") ? value : `${value.replace(" ", "T")}Z`;
}
