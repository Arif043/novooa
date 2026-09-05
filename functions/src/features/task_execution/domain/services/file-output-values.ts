import {type WrittenFile} from "../../../files/domain/repositories/team-file-store.js";
import {
  mediaReferenceFor,
  type FileReference,
  type NodeOutputValue,
} from "../entities/workflow-value.js";

export function fileReferenceFor(file: WrittenFile): FileReference {
  return {
    fileId: file.fileId,
    versionId: file.versionId,
    displayName: file.displayName,
    contentType: file.contentType,
    sizeBytes: file.sizeBytes,
  };
}

export function fileOutputFor(file: WrittenFile): NodeOutputValue {
  const reference = fileReferenceFor(file);
  if (reference.contentType.startsWith("image/")) {
    return {type: "media", value: mediaReferenceFor(reference)};
  }
  return {type: "file", value: reference};
}

export function fileMetadataOutputs(file: WrittenFile) {
  return {
    fileId: {type: "string" as const, value: file.fileId},
    versionId: {type: "string" as const, value: file.versionId},
    displayName: {type: "string" as const, value: file.displayName},
    contentType: {type: "string" as const, value: file.contentType},
    sizeBytes: {type: "number" as const, value: file.sizeBytes},
    folderId: {type: "json" as const, value: file.folderId},
    isNewFile: {type: "boolean" as const, value: file.isNewFile},
  };
}
