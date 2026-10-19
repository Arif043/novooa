import {mkdir, mkdtemp, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import {type TeamMember, type TeamworkNodeConfig} from "../../../domain/entities/teamwork-config.js";
import {type Employee} from "../../../../employees/domain/entities/employee.js";
import {type NodeAttachmentWorkspace} from "./node-attachment-workspace.js";
import {prepareKnowledgeFiles} from "./knowledge-note-workspace.js";
import {prepareSkillDirectory} from "./skill-workspace.js";
import {type ResolvedEmployee} from "./task-definition.js";
import {downloadAttachments, loadEmployee, type NodeAttachmentSources} from "./workspace-contents.js";

/** Ordner im Arbeitsordner, in dem das Team Zwischenergebnisse und Ergebnisdateien ablegt. */
export const sharedDirectoryName = "shared";

export type ResolvedTeamMember = {
  employee: ResolvedEmployee;
  responsibility: string;
  languageModelId?: string;
  /** `employees/<id>/skills` — nur dieser Mitarbeiter bekommt ihn als Skill-Pfad. */
  skillsDirectory?: string;
};

export type TeamWorkspace = {
  /** Absoluter Pfad zu `shared/`. */
  sharedDirectory: string;
  members: ResolvedTeamMember[];
};

/**
 * Ein Arbeitsordner für Orchestrator und Mitarbeiter: Anhänge und `knowledge/` wie beim Prompt-Baustein,
 * `shared/` für die gemeinsame Arbeit und je Mitarbeiter ein eigener Ordner mit seinen Fähigkeiten.
 * Die Mitarbeiter werden frisch geladen; Änderungen an ihnen gelten sofort.
 */
export async function prepareTeamworkWorkspace(
  config: TeamworkNodeConfig, teamId: string, sources: NodeAttachmentSources,
): Promise<NodeAttachmentWorkspace> {
  const employees = await Promise.all(
    config.members.map((member) => loadEmployee(teamId, member.employeeId, sources.employeeStore)),
  );
  const rootDirectory = await mkdtemp(path.join(os.tmpdir(), "novooa-teamwork-"));
  try {
    const sharedDirectory = path.join(rootDirectory, sharedDirectoryName);
    await mkdir(sharedDirectory, {recursive: true});
    const members = await Promise.all(config.members.map(
      (member, index) => resolvedMember(member, employees[index], rootDirectory, sources),
    ));
    return {
      rootDirectory,
      files: await downloadAttachments(rootDirectory, config.attachments, sources.objectStore),
      knowledgeFiles: await prepareKnowledgeFiles(rootDirectory, teamId, config.knowledgeAttachments, sources.knowledgeBaseStore),
      skillCount: 0,
      team: {sharedDirectory, members},
      cleanup: () => rm(rootDirectory, {recursive: true, force: true}),
    };
  } catch (error) {
    await rm(rootDirectory, {recursive: true, force: true});
    throw error;
  }
}

async function resolvedMember(
  member: TeamMember, employee: Employee, rootDirectory: string, sources: NodeAttachmentSources,
): Promise<ResolvedTeamMember> {
  const {id, name, constraint, skills} = employee;
  const skillsDirectory = await prepareSkillDirectory(
    path.join(rootDirectory, "employees", id),
    skills.map((skill) => ({name: skill, description: ""})),
    sources.skillContentReader,
  );
  return {
    employee: {id, name, constraint},
    responsibility: member.responsibility.trim(),
    languageModelId: member.languageModelId,
    skillsDirectory,
  };
}
