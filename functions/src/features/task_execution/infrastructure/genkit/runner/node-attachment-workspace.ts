import {type SkillContentReader} from "../../../../skills/domain/repositories/skill-content-reader.js";
import {mkdir, mkdtemp, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import {type KnowledgeBaseStore} from
  "../../../../knowledge_base/domain/repositories/knowledge-base-store.js";
import {type Employee} from "../../../../employees/domain/entities/employee.js";
import {type EmployeeStore} from "../../../../employees/domain/repositories/employee-store.js";
import {type ObjectStore} from "../../../../files/domain/repositories/object-store.js";
import {
  type KnowledgeAttachment,
  type NodeAttachment,
  type ResolvedEmployee,
  type SkillAttachment,
  type WorkflowNode,
} from "./task-definition.js";
import {
  prepareKnowledgeFiles,
  type PreparedKnowledgeAttachment,
} from "./knowledge-note-workspace.js";
import {prepareSkillDirectory} from "./skill-workspace.js";
import {assertExclusiveDelegation, employeeIdFor, ownSkillAttachmentsFor} from "./employee-context.js";

export type PreparedNodeAttachment = NodeAttachment & {
  filename: string;
};

export type NodeAttachmentWorkspace = {
  rootDirectory: string;
  /** Der Mitarbeiter des Bausteins (System-Prompt), falls einer zugewiesen ist. */
  employee?: ResolvedEmployee;
  files: PreparedNodeAttachment[];
  knowledgeFiles: PreparedKnowledgeAttachment[];
  skillsDirectory?: string;
  skillCount: number;
  cleanup(): Promise<void>;
};

/** Woher der Workspace eines Bausteins seine Inhalte holt. */
export type NodeAttachmentSources = {
  objectStore: ObjectStore;
  knowledgeBaseStore: KnowledgeBaseStore;
  skillContentReader?: SkillContentReader;
  employeeStore?: EmployeeStore;
};

export async function prepareNodeAttachmentWorkspace(
  node: WorkflowNode,
  teamId: string,
  sources: NodeAttachmentSources,
): Promise<NodeAttachmentWorkspace | undefined> {
  assertExclusiveDelegation(node);
  const employee = await employeeFor(node, teamId, sources.employeeStore);
  const attachments = attachmentsFor(node);
  const knowledgeAttachments = knowledgeAttachmentsFor(node);
  // Mit Mitarbeiter gelten dessen Fähigkeiten, sonst die des Bausteins.
  const skillAttachments = employee === undefined
    ? ownSkillAttachmentsFor(node)
    : employee.skills.map((name) => ({name, description: ""}));
  if (
    employee === undefined &&
    attachments.length === 0 &&
    knowledgeAttachments.length === 0 &&
    skillAttachments.length === 0
  ) {
    return undefined;
  }
  const rootDirectory = await mkdtemp(path.join(os.tmpdir(), "syscat-node-files-"));
  try {
    return await buildWorkspace({
      rootDirectory, teamId, sources, attachments, knowledgeAttachments, skillAttachments, employee,
    });
  } catch (error) {
    await rm(rootDirectory, {recursive: true, force: true});
    throw error;
  }
}

async function buildWorkspace(input: {
  rootDirectory: string;
  teamId: string;
  sources: NodeAttachmentSources;
  attachments: NodeAttachment[];
  knowledgeAttachments: KnowledgeAttachment[];
  skillAttachments: SkillAttachment[];
  employee: Employee | undefined;
}): Promise<NodeAttachmentWorkspace> {
  const {rootDirectory, sources} = input;
  await mkdir(rootDirectory, {recursive: true});
  const files = await downloadAttachments(rootDirectory, input.attachments, sources.objectStore);
  const knowledgeFiles = await prepareKnowledgeFiles(
    rootDirectory, input.teamId, input.knowledgeAttachments, sources.knowledgeBaseStore,
  );
  const skillsDirectory = await prepareSkillDirectory(rootDirectory, input.skillAttachments, sources.skillContentReader);
  return {
    rootDirectory,
    ...(input.employee ? {employee: {id: input.employee.id, name: input.employee.name, constraint: input.employee.constraint}} : {}),
    files,
    knowledgeFiles,
    skillsDirectory,
    skillCount: new Set(input.skillAttachments.map((skill) => skill.name)).size,
    cleanup: () => rm(rootDirectory, {recursive: true, force: true}),
  };
}

/** Lädt den Mitarbeiter des Bausteins frisch aus dem Speicher; ein gelöschter Mitarbeiter bricht den Lauf lesbar ab. */
async function employeeFor(node: WorkflowNode, teamId: string, store?: EmployeeStore): Promise<Employee | undefined> {
  const employeeId = employeeIdFor(node);
  if (employeeId === undefined) return undefined;
  if (store === undefined) throw new Error("Mitarbeiter sind in dieser Umgebung nicht verfügbar.");
  const employee = await store.find(teamId, employeeId);
  if (employee === null) {
    throw new Error("Der zugewiesene Mitarbeiter wurde nicht gefunden. Wurde er gelöscht? Wähle im Baustein einen anderen Mitarbeiter.");
  }
  return employee;
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
