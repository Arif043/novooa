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
};

async function writeTeamFile(input: WriteFileInput): Promise<WrittenFile> {
  initializeAdminApp();
  const file = writtenFileFrom(input);
  await getStorage().bucket().file(file.storagePath).save(input.content, {
    contentType: file.contentType,
  });
  await writeMetadata(input.teamId, file);
  return file;
}

function writtenFileFrom(input: WriteFileInput): WrittenFile {
  const fileId = randomUUID();
  const versionId = randomUUID();
  const displayName = fileNameFor(input.node);
  const contentType = contentTypeFor(input.node);
  return {
    fileId,
    versionId,
    displayName,
    contentType,
    sizeBytes: Buffer.byteLength(input.content, "utf8"),
    storagePath: storagePathFor(input.teamId, fileId, versionId, displayName),
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
  batch.set(fileReference, fileDocument(teamId, file));
  batch.set(
    fileReference.collection("versions").doc(file.versionId),
    versionDocument(file),
  );
  await batch.commit();
}

function fileDocument(teamId: string, file: WrittenFile) {
  return {
    teamId,
    ownerUid: "system",
    displayName: file.displayName,
    folderId: null,
    storagePath: file.storagePath,
    currentVersionId: file.versionId,
    contentType: file.contentType,
    sizeBytes: file.sizeBytes,
    createdAt: FieldValue.serverTimestamp(),
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

function fileNameFor(node: WorkflowNode): string {
  const value = node.config.primitive === "writeFile" ? node.config.fileName : "";
  return sanitizedName(value || "ausgabe.txt");
}

function contentTypeFor(node: WorkflowNode): string {
  if (node.config.primitive !== "writeFile") return "text/plain";
  return node.config.contentType.trim() || "text/plain";
}

function storagePathFor(
  teamId: string,
  fileId: string,
  versionId: string,
  fileName: string,
): string {
  return `teams/${teamId}/files/${fileId}/versions/${versionId}/${fileName}`;
}

function sanitizedName(value: string): string {
  return value.trim().replace(/[\\/]/g, "_");
}

function initializeAdminApp(): void {
  if (getApps().length === 0) initializeApp();
}
