import {type TeamworkExecutionRequest} from "../../../../domain/entities/teamwork-execution.js";
import {defaultGenerationOptions} from "../../../../../language_models/domain/entities/generation-options.js";
import {EmployeeConversation} from "../../runner/employee-conversation.js";
import {type NodeAttachmentWorkspace} from "../../runner/node-attachment-workspace.js";
import {type ResolvedTeamMember, type TeamWorkspace} from "../../runner/teamwork-workspace.js";
import {type TeamMemberRun} from "./teamwork-delegation-tools.js";
import {teamworkMiddleware} from "./teamwork-middleware.js";
import {teamworkModelFor, type TeamworkModelSources} from "./teamwork-model.js";
import {memberSystemPrompt} from "./teamwork-prompts.js";

/** Bereitet jeden Mitarbeiter vor: eigenes Modell, eindeutiger Werkzeugname, eigene Fähigkeiten, ein Gespräch für den Lauf. */
export async function teamMemberRuns(
  request: TeamworkExecutionRequest,
  workspace: NodeAttachmentWorkspace & {team: TeamWorkspace},
  sources: TeamworkModelSources,
): Promise<TeamMemberRun[]> {
  const toolNames = uniqueToolNames(workspace.team.members.map((member) => member.employee.name));
  return Promise.all(workspace.team.members.map((member, index) =>
    memberRunFor(member, toolNames[index], request.teamId, workspace.rootDirectory, sources)));
}

async function memberRunFor(
  member: ResolvedTeamMember, toolName: string, teamId: string, rootDirectory: string, sources: TeamworkModelSources,
): Promise<TeamMemberRun> {
  const model = await teamworkModelFor(
    {languageModelId: member.languageModelId, teamId, generationOptions: defaultGenerationOptions},
    sources,
  );
  const use = teamworkMiddleware(rootDirectory, member.skillsDirectory);
  return {
    toolName,
    employeeId: member.employee.id,
    employeeName: member.employee.name,
    responsibility: member.responsibility,
    conversation: new EmployeeConversation({
      ai: model.ai, employee: member.employee, system: memberSystemPrompt(member.employee), model: model.model, use, config: model.config,
    }),
  };
}

/** `delegate_to_<name>` aus ASCII-Zeichen; gleiche Namen bekommen eine Nummer. */
export function uniqueToolNames(employeeNames: string[]): string[] {
  const used = new Map<string, number>();
  return employeeNames.map((name, index) => {
    const slug = name.normalize("NFKD").replace(/[̀-ͯ]/g, "").toLowerCase()
      .replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "").slice(0, 40) || `member_${index + 1}`;
    const count = (used.get(slug) ?? 0) + 1;
    used.set(slug, count);
    return `delegate_to_${count === 1 ? slug : `${slug}_${count}`}`;
  });
}
