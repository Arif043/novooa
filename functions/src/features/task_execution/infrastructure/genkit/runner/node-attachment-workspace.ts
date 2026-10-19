import {mkdir, mkdtemp, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import {type Employee} from "../../../../employees/domain/entities/employee.js";
import {type EmployeeStore} from "../../../../employees/domain/repositories/employee-store.js";
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
import {prepareTeamworkWorkspace, type TeamWorkspace} from "./teamwork-workspace.js";
import {
  downloadAttachments,
  loadEmployee,
  type NodeAttachmentSources,
  type PreparedNodeAttachment,
} from "./workspace-contents.js";

export type {NodeAttachmentSources, PreparedNodeAttachment} from "./workspace-contents.js";

export type NodeAttachmentWorkspace = {
  rootDirectory: string;
  /** Der Mitarbeiter des Bausteins (System-Prompt), falls einer zugewiesen ist. */
  employee?: ResolvedEmployee;
  /** Nur beim Baustein „Teamarbeit“: gemeinsamer Arbeitsordner und die Mitarbeiter des Teams. */
  team?: TeamWorkspace;
  files: PreparedNodeAttachment[];
  knowledgeFiles: PreparedKnowledgeAttachment[];
  skillsDirectory?: string;
  skillCount: number;
  cleanup(): Promise<void>;
};

export async function prepareNodeAttachmentWorkspace(
  node: WorkflowNode,
  teamId: string,
  sources: NodeAttachmentSources,
): Promise<NodeAttachmentWorkspace | undefined> {
  if (node.config.primitive === "teamwork") return prepareTeamworkWorkspace(node.config, teamId, sources);
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

async function employeeFor(node: WorkflowNode, teamId: string, store?: EmployeeStore): Promise<Employee | undefined> {
  const employeeId = employeeIdFor(node);
  return employeeId === undefined ? undefined : loadEmployee(teamId, employeeId, store);
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
