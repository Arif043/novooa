import {type NodeAttachment} from "../../../task_execution/domain/entities/attachments.js";

export type FileContent = string | Uint8Array;

export type WriteTeamFileInput = {
  teamId: string;
  content: FileContent;
  fileName: string;
  contentType: string;
  targetFileId: string | null;
};

export type WrittenFile = {
  fileId: string;
  versionId: string;
  storagePath: string;
  displayName: string;
  contentType: string;
  sizeBytes: number;
  folderId: string | null;
  ownerUid: string;
  isNewFile: boolean;
};

export type StoredTeamFile = Pick<
  WrittenFile,
  | "fileId"
  | "versionId"
  | "storagePath"
  | "displayName"
  | "contentType"
  | "sizeBytes"
>;

export interface TeamFileStore {
  writeTeamFile(input: WriteTeamFileInput): Promise<WrittenFile>;
  loadTeamFile(teamId: string, fileId: string): Promise<StoredTeamFile>;
  readTextFile(teamId: string, file: NodeAttachment): Promise<string>;
}

export function contentSizeBytes(content: FileContent): number {
  if (typeof content === "string") return new TextEncoder().encode(content).byteLength;
  return content.byteLength;
}
