import {type NodeAttachment} from "../task-definition.js";

export type WriteTeamFileInput = {
  teamId: string;
  content: string;
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

export interface TeamFileStore {
  writeTeamFile(input: WriteTeamFileInput): Promise<WrittenFile>;
  readTextFile(teamId: string, file: NodeAttachment): Promise<string>;
}
