import {randomUUID} from "node:crypto";
import {type FileEvent} from "../../domain/entities/file-event.js";
import {storagePathFor} from "../../domain/entities/file-storage-path.js";
import {contentSizeBytes, type WriteTeamFileInput, type WrittenFile} from "../../domain/repositories/team-file-store.js";

type ExistingFile = {fileId: string; ownerUid: string; folderId: string | null};

export function writtenEventFrom(teamId: string, file: WrittenFile, triggerChain: readonly string[]): FileEvent {
  return {
    type: file.isNewFile ? "fileCreated" : "fileVersionCreated",
    teamId, fileId: file.fileId, versionId: file.versionId, displayName: file.displayName,
    contentType: file.contentType, sizeBytes: file.sizeBytes, folderId: file.folderId,
    occurredAt: new Date().toISOString(), triggerChain,
  };
}

export function deletedEventFrom(
  teamId: string,
  file: {id: string; display_name: string; folder_id: string | null; content_type: string; size_bytes: number},
): FileEvent {
  return {
    type: "fileDeleted", teamId, fileId: file.id, versionId: null, displayName: file.display_name,
    contentType: file.content_type, sizeBytes: file.size_bytes, folderId: file.folder_id,
    occurredAt: new Date().toISOString(), triggerChain: [],
  };
}

export function newFileFrom(input: WriteTeamFileInput): WrittenFile {
  const fileId = randomUUID();
  const versionId = randomUUID();
  return writtenFile(input, fileId, versionId, {folderId: input.folderId ?? null, ownerUid: "system"}, true);
}

export function versionFromExisting(
  input: WriteTeamFileInput,
  existingFile: ExistingFile,
): WrittenFile {
  return writtenFile(
    input,
    existingFile.fileId,
    randomUUID(),
    existingFile,
    false,
  );
}

function writtenFile(
  input: WriteTeamFileInput,
  fileId: string,
  versionId: string,
  owner: Pick<ExistingFile, "folderId" | "ownerUid">,
  isNewFile: boolean,
): WrittenFile {
  return {
    fileId,
    versionId,
    displayName: input.fileName,
    contentType: input.contentType,
    sizeBytes: contentSizeBytes(input.content),
    folderId: owner.folderId,
    ownerUid: owner.ownerUid,
    isNewFile,
    storagePath: storagePathFor(input.teamId, fileId, versionId, input.fileName),
  };
}
