import {randomUUID} from "node:crypto";
import {FieldValue} from "firebase-admin/firestore";
import {storagePathFor} from "../../domain/entities/file-storage-path.js";
import {type NodeAttachment} from "../../../task_execution/domain/entities/attachments.js";
import {getDefaultStorageBucket} from "./firebase-storage.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
import {
  type TeamFileContent,
  type TeamFileContentReader,
} from "../../domain/repositories/team-file-content-reader.js";
import {
  contentSizeBytes,
  type StoredTeamFile,
  type TeamFileStore,
  type WriteTeamFileInput,
  type WrittenFile,
} from "../../domain/repositories/team-file-store.js";

type ExistingFile = {
  fileId: string;
  ownerUid: string;
  folderId: string | null;
};

export class FirestoreTeamFileStore implements TeamFileStore, TeamFileContentReader {
  async writeTeamFile(input: WriteTeamFileInput): Promise<WrittenFile> {
    const file = await this.writtenFileFrom(input);
    await getDefaultStorageBucket().file(file.storagePath).save(input.content, {
      contentType: file.contentType,
    });
    await writeMetadata(input.teamId, file);
    return file;
  }

  async readTextFile(teamId: string, file: NodeAttachment): Promise<string> {
    ensureTeamFile(file, teamId);
    const storageFile = getDefaultStorageBucket().file(file.storagePath);
    const [content] = await storageFile.download();
    return content.toString("utf8");
  }

  async loadTeamFile(
    teamId: string,
    fileId: string,
  ): Promise<StoredTeamFile> {
    const snapshot = await filesReference(teamId).doc(fileId).get();
    if (!snapshot.exists) throw new Error(`Datei nicht gefunden: ${fileId}`);
    return storedTeamFileFrom(snapshot.id, snapshot.data() ?? {});
  }

  async readTeamFileContent(
    teamId: string,
    fileId: string,
    versionId: string,
  ): Promise<TeamFileContent> {
    const file = await storedTeamFileVersionFor(teamId, fileId, versionId);
    const [content] = await getDefaultStorageBucket().file(file.storagePath)
      .download();
    return {
      content,
      displayName: file.displayName,
      contentType: file.contentType,
      sizeBytes: file.sizeBytes,
    };
  }

  private async writtenFileFrom(
    input: WriteTeamFileInput,
  ): Promise<WrittenFile> {
    if (input.targetFileId !== null) return this.versionedFileFrom(input);
    const existingFile = await this.existingFileByNameFor(input);
    if (existingFile !== null) return versionFromExisting(input, existingFile);
    return newFileFrom(input);
  }

  private async versionedFileFrom(
    input: WriteTeamFileInput,
  ): Promise<WrittenFile> {
    const existingFile = await this.existingFileFor(input);
    return versionFromExisting(input, existingFile);
  }

  private async existingFileFor(
    input: WriteTeamFileInput,
  ): Promise<ExistingFile> {
    if (input.targetFileId === null) throw new Error("Datei-ID fehlt.");
    const snapshot = await filesReference(input.teamId).doc(input.targetFileId)
      .get();
    if (!snapshot.exists) {
      throw new Error(`Datei nicht gefunden: ${input.targetFileId}`);
    }
    return existingFileFrom(snapshot.id, snapshot.data() ?? {});
  }

  private async existingFileByNameFor(
    input: WriteTeamFileInput,
  ): Promise<ExistingFile | null> {
    const snapshot = await filesReference(input.teamId)
      .where("displayName", "==", input.fileName)
      .where("folderId", "==", null)
      .limit(1)
      .get();
    const document = snapshot.docs[0];
    if (!document) return null;
    return existingFileFrom(document.id, document.data());
  }
}

function newFileFrom(input: WriteTeamFileInput): WrittenFile {
  const versionId = randomUUID();
  const fileId = randomUUID();
  return {
    fileId,
    versionId,
    displayName: input.fileName,
    contentType: input.contentType,
    sizeBytes: contentSizeBytes(input.content),
    folderId: null,
    ownerUid: "system",
    isNewFile: true,
    storagePath: storagePathFor(input.teamId, fileId, versionId, input.fileName),
  };
}

function versionFromExisting(
  input: WriteTeamFileInput,
  existingFile: ExistingFile,
): WrittenFile {
  const versionId = randomUUID();
  return {
    fileId: existingFile.fileId,
    versionId,
    displayName: input.fileName,
    contentType: input.contentType,
    sizeBytes: contentSizeBytes(input.content),
    folderId: existingFile.folderId,
    ownerUid: existingFile.ownerUid,
    isNewFile: false,
    storagePath: storagePathFor(
      input.teamId,
      existingFile.fileId,
      versionId,
      input.fileName,
    ),
  };
}

async function writeMetadata(teamId: string, file: WrittenFile): Promise<void> {
  const fileReference = filesReference(teamId).doc(file.fileId);
  const batch = getDatabase().batch();
  batch.set(fileReference, fileDocument(teamId, file), {merge: true});
  batch.set(
    fileReference.collection("versions").doc(file.versionId),
    versionDocument(file),
  );
  await batch.commit();
}

function fileDocument(teamId: string, file: WrittenFile) {
  return {
    teamId,
    ownerUid: file.ownerUid,
    displayName: file.displayName,
    folderId: file.folderId,
    storagePath: file.storagePath,
    currentVersionId: file.versionId,
    contentType: file.contentType,
    sizeBytes: file.sizeBytes,
    currentVersionCreatedAt: FieldValue.serverTimestamp(),
    ...(file.isNewFile ? {createdAt: FieldValue.serverTimestamp()} : {}),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function versionDocument(file: WrittenFile) {
  return {
    id: file.versionId,
    fileId: file.fileId,
    createdByUid: "system",
    displayName: file.displayName,
    storagePath: file.storagePath,
    contentType: file.contentType,
    sizeBytes: file.sizeBytes,
    createdAt: FieldValue.serverTimestamp(),
  };
}

function existingFileFrom(
  fileId: string,
  data: Record<string, unknown>,
): ExistingFile {
  return {
    fileId,
    ownerUid: stringFrom(data.ownerUid, "system"),
    folderId: nullableStringFrom(data.folderId),
  };
}

function storedTeamFileFrom(
  fileId: string,
  data: Record<string, unknown>,
): StoredTeamFile {
  return {
    fileId,
    versionId: stringFrom(data.currentVersionId, ""),
    storagePath: stringFrom(data.storagePath, ""),
    displayName: stringFrom(data.displayName, "Unbenannte Datei"),
    contentType: stringFrom(data.contentType, "application/octet-stream"),
    sizeBytes: numberFrom(data.sizeBytes),
  };
}

async function storedTeamFileVersionFor(
  teamId: string,
  fileId: string,
  versionId: string,
): Promise<StoredTeamFile> {
  const snapshot = await filesReference(teamId).doc(fileId)
    .collection("versions").doc(versionId).get();
  if (!snapshot.exists) throw new Error(`Dateiversion nicht gefunden: ${versionId}`);
  return storedTeamFileVersionFrom(fileId, versionId, snapshot.data() ?? {});
}

function storedTeamFileVersionFrom(
  fileId: string,
  versionId: string,
  data: Record<string, unknown>,
): StoredTeamFile {
  return {
    fileId,
    versionId,
    storagePath: stringFrom(data.storagePath, ""),
    displayName: stringFrom(data.displayName, "Unbenannte Datei"),
    contentType: stringFrom(data.contentType, "application/octet-stream"),
    sizeBytes: numberFrom(data.sizeBytes),
  };
}

function ensureTeamFile(file: NodeAttachment, teamId: string): void {
  if (file.storagePath.startsWith(`teams/${teamId}/files/`)) return;
  throw new Error("Datei lesen: Die Datei gehört nicht zum aktuellen Team.");
}

function filesReference(teamId: string) {
  return getDatabase().collection("teams").doc(teamId).collection("files");
}

function stringFrom(value: unknown, fallback: string): string {
  return typeof value === "string" && value.trim().length > 0 ? value : fallback;
}

function nullableStringFrom(value: unknown): string | null {
  return typeof value === "string" && value.trim().length > 0 ? value : null;
}

function numberFrom(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}
