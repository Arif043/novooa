import {randomUUID} from "node:crypto";
import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";
import {
  type NodeExecutor,
  executedNode,
  parentOutputFor,
} from "../task-runner/node-executor.js";
import {type WorkflowNode} from "../task-runner/task-definition.js";
import {
  contentTypeFor,
  fileNameFor,
  storagePathFor,
  targetFileIdFor,
} from "./write-file-node-config.js";

export const writeFileNodeExecutor: NodeExecutor = {
  primitive: "writeFile",
  async execute(input) {
    const content = parentOutputFor(
      input.node,
      input.runContext.task,
      input.runContext.results,
    );
    const file = await writeTeamFile({
      teamId: input.runContext.teamId,
      node: input.node,
      content,
    });
    return executedNode(input.node, JSON.stringify(file));
  },
};

type WriteFileInput = {
  teamId: string;
  node: WorkflowNode;
  content: string;
};

type WrittenFile = {
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

async function writeTeamFile(input: WriteFileInput): Promise<WrittenFile> {
  initializeAdminApp();
  const file = await writtenFileFrom(input);
  await getStorage().bucket().file(file.storagePath).save(input.content, {
    contentType: file.contentType,
  });
  await writeMetadata(input.teamId, file);
  return file;
}

async function writtenFileFrom(input: WriteFileInput): Promise<WrittenFile> {
  if (targetFileIdFor(input.node) !== null) return versionedFileFrom(input);
  return newFileFrom(input);
}

function newFileFrom(input: WriteFileInput): WrittenFile {
  const versionId = randomUUID();
  const fileId = randomUUID();
  const displayName = fileNameFor(input.node);
  const contentType = contentTypeFor(input.node);
  return {
    fileId,
    versionId,
    displayName,
    contentType,
    sizeBytes: Buffer.byteLength(input.content, "utf8"),
    folderId: null,
    ownerUid: "system",
    isNewFile: true,
    storagePath: storagePathFor(input.teamId, fileId, versionId, displayName),
  };
}

async function versionedFileFrom(input: WriteFileInput): Promise<WrittenFile> {
  const existingFile = await existingFileFor(input);
  const versionId = randomUUID();
  const displayName = fileNameFor(input.node);
  const contentType = contentTypeFor(input.node);
  return {
    fileId: existingFile.fileId,
    versionId,
    displayName,
    contentType,
    sizeBytes: Buffer.byteLength(input.content, "utf8"),
    folderId: existingFile.folderId,
    ownerUid: existingFile.ownerUid,
    isNewFile: false,
    storagePath: storagePathFor(input.teamId, existingFile.fileId, versionId, displayName),
  };
}

async function writeMetadata(teamId: string, file: WrittenFile): Promise<void> {
  const database = getFirestore();
  const fileReference = database
    .collection("teams")
    .doc(teamId)
    .collection("files")
    .doc(file.fileId);
  const batch = database.batch();
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

type ExistingFile = {
  fileId: string;
  ownerUid: string;
  folderId: string | null;
};

async function existingFileFor(input: WriteFileInput): Promise<ExistingFile> {
  const fileId = targetFileIdFor(input.node);
  if (fileId === null) throw new Error("Datei-ID fehlt.");
  const snapshot = await getFirestore()
    .collection("teams")
    .doc(input.teamId)
    .collection("files")
    .doc(fileId)
    .get();
  if (!snapshot.exists) throw new Error(`Datei nicht gefunden: ${fileId}`);
  const data = snapshot.data() ?? {};
  return {
    fileId,
    ownerUid: stringFrom(data.ownerUid, "system"),
    folderId: nullableStringFrom(data.folderId),
  };
}

function stringFrom(value: unknown, fallback: string): string {
  return typeof value === "string" && value.trim().length > 0 ? value : fallback;
}

function nullableStringFrom(value: unknown): string | null {
  return typeof value === "string" && value.trim().length > 0 ? value : null;
}

function initializeAdminApp(): void {
  if (getApps().length === 0) initializeApp();
}
