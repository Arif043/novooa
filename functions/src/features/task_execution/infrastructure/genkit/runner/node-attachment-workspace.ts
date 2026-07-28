import {mkdir, mkdtemp, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import {type KnowledgeBaseStore} from
  "../../../../knowledge_base/domain/repositories/knowledge-base-store.js";
import {type ObjectStore} from "../../../../files/domain/repositories/object-store.js";
import {
  type KnowledgeAttachment,
  type NodeAttachment,
  type SkillAttachment,
  type WorkflowNode,
} from "./task-definition.js";
import {
  prepareKnowledgeFiles,
  type PreparedKnowledgeAttachment,
} from "./knowledge-note-workspace.js";
import {prepareSkillDirectory} from "./skill-workspace.js";
import {employeeFor, mergeNodeAndEmployeeSkills} from "./employee-context.js";

export type PreparedNodeAttachment = NodeAttachment & {
  filename: string;
};

export type NodeAttachmentWorkspace = {
  rootDirectory: string;
  files: PreparedNodeAttachment[];
  knowledgeFiles: PreparedKnowledgeAttachment[];
  skillsDirectory?: string;
  skillCount: number;
  cleanup(): Promise<void>;
};

export async function prepareNodeAttachmentWorkspace(
  node: WorkflowNode,
  teamId: string,
  objectStore: ObjectStore,
  knowledgeBaseStore: KnowledgeBaseStore,
): Promise<NodeAttachmentWorkspace | undefined> {
  const attachments = attachmentsFor(node);
  const knowledgeAttachments = knowledgeAttachmentsFor(node);
  const nodeSkills = skillAttachmentsFor(node);
  const skillAttachments = mergeNodeAndEmployeeSkills(
    nodeSkills,
    employeeFor(node),
  );
  if (
    attachments.length === 0 &&
    knowledgeAttachments.length === 0 &&
    skillAttachments.length === 0
  ) {
    return undefined;
  }
  const rootDirectory = await mkdtemp(
    path.join(os.tmpdir(), "syscat-node-files-"),
  );
  await mkdir(rootDirectory, {recursive: true});
  const files = await downloadAttachments(rootDirectory, attachments, objectStore);
  const knowledgeFiles = await prepareKnowledgeFiles(
    rootDirectory,
    teamId,
    knowledgeAttachments,
    knowledgeBaseStore,
  );
  const skillsDirectory = await prepareSkillDirectory(
    rootDirectory,
    skillAttachments,
    objectStore,
  );
  return {
    rootDirectory,
    files,
    knowledgeFiles,
    skillsDirectory,
    skillCount: skillAttachments.length,
    cleanup: () => rm(rootDirectory, {recursive: true, force: true}),
  };
}

function attachmentsFor(node: WorkflowNode): NodeAttachment[] {
  if (node.config.primitive === "prompt") return node.config.attachments;
  if (node.config.primitive === "script") return node.config.attachments;
  return [];
}

function knowledgeAttachmentsFor(node: WorkflowNode): KnowledgeAttachment[] {
  if (node.config.primitive === "prompt") {
    return node.config.knowledgeAttachments;
  }
  return [];
}

function skillAttachmentsFor(node: WorkflowNode): SkillAttachment[] {
  if (node.config.primitive === "prompt") {
    return node.config.skillAttachments;
  }
  if (node.config.primitive === "iterativeRefinement") {
    return node.config.skillAttachments;
  }
  return [];
}

async function downloadAttachments(
  rootDirectory: string,
  attachments: NodeAttachment[],
  objectStore: ObjectStore,
): Promise<PreparedNodeAttachment[]> {
  return Promise.all(
    attachments.map((attachment, index) =>
      downloadAttachment(rootDirectory, attachment, index, objectStore),
    ),
  );
}

async function downloadAttachment(
  rootDirectory: string,
  attachment: NodeAttachment,
  index: number,
  objectStore: ObjectStore,
): Promise<PreparedNodeAttachment> {
  const filename = safeFilename(attachment.displayName, index);
  const destination = path.join(rootDirectory, filename);
  await objectStore.downloadToFile(attachment.storagePath, destination);
  return {...attachment, filename};
}

function safeFilename(displayName: string, index: number): string {
  const fallback = `datei-${index + 1}`;
  const normalized = displayName.trim() || fallback;
  const safeName = normalized.replace(/[^a-zA-Z0-9._-]+/g, "_");
  return `${index + 1}-${safeName.slice(0, 120)}`;
}
