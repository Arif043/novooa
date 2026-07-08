import {mkdir, mkdtemp, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import {getApps, initializeApp} from "firebase-admin/app";
import {getStorage} from "firebase-admin/storage";
import {
  type NodeAttachment,
  type WorkflowNode,
} from "./task-definition.js";

if (getApps().length === 0) initializeApp();

export type PreparedNodeAttachment = NodeAttachment & {
  filename: string;
};

export type NodeAttachmentWorkspace = {
  rootDirectory: string;
  files: PreparedNodeAttachment[];
  cleanup(): Promise<void>;
};

export async function prepareNodeAttachmentWorkspace(
  node: WorkflowNode,
): Promise<NodeAttachmentWorkspace | undefined> {
  const attachments = attachmentsFor(node);
  if (attachments.length === 0) return undefined;
  const rootDirectory = await mkdtemp(
    path.join(os.tmpdir(), "syscat-node-files-"),
  );
  await mkdir(rootDirectory, {recursive: true});
  const files = await downloadAttachments(rootDirectory, attachments);
  return {
    rootDirectory,
    files,
    cleanup: () => rm(rootDirectory, {recursive: true, force: true}),
  };
}

function attachmentsFor(node: WorkflowNode): NodeAttachment[] {
  if (node.config.primitive === "prompt") return node.config.attachments;
  if (node.config.primitive === "script") return node.config.attachments;
  return [];
}

async function downloadAttachments(
  rootDirectory: string,
  attachments: NodeAttachment[],
): Promise<PreparedNodeAttachment[]> {
  return Promise.all(
    attachments.map((attachment, index) =>
      downloadAttachment(rootDirectory, attachment, index),
    ),
  );
}

async function downloadAttachment(
  rootDirectory: string,
  attachment: NodeAttachment,
  index: number,
): Promise<PreparedNodeAttachment> {
  const filename = safeFilename(attachment.displayName, index);
  const destination = path.join(rootDirectory, filename);
  await getStorage().bucket().file(attachment.storagePath).download({
    destination,
  });
  return {...attachment, filename};
}

function safeFilename(displayName: string, index: number): string {
  const fallback = `datei-${index + 1}`;
  const normalized = displayName.trim() || fallback;
  const safeName = normalized.replace(/[^a-zA-Z0-9._-]+/g, "_");
  return `${index + 1}-${safeName.slice(0, 120)}`;
}
