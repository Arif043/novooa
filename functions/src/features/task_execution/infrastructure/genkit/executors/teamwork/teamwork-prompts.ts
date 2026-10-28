import {type TeamworkOutputField} from "../../../../domain/entities/teamwork-config.js";
import {type LlmPrompt} from "../../../../../language_models/domain/prompting/llm-prompt.js";
import {PromptBuilder} from "../../../../../language_models/domain/prompting/prompt-builder.js";
import {sameAsTask} from "../../../../../language_models/domain/prompting/response-language.js";
import {XmlPromptRenderer} from "../../../../../language_models/domain/prompting/xml-prompt-renderer.js";
import {type NodeAttachmentWorkspace} from "../../runner/node-attachment-workspace.js";
import {type ResolvedEmployee} from "../../runner/task-definition.js";
import {attachmentsSectionFor, roleWithEmployee} from "../workflow-prompt-sections.js";
import {teamworkImageInstructions} from "./teamwork-images.js";
import {fileFieldsHint, workspaceHint} from "./teamwork-prompt-sections.js";

/** Höchstens so viele Aufträge vergibt der Orchestrator in einem Lauf. */
export const maximumDelegations = 10;

export type TeamMemberTool = {toolName: string; employeeId: string; employeeName: string; responsibility: string};

/** Ein Auftrag des Orchestrators an einen Mitarbeiter. */
export type TeamworkTask = {task: string; expectedResult: string; boundaries?: string};

const renderer = new XmlPromptRenderer();

const orchestratorRules = [
  "Assign subtasks with the delegate_to_… tools. Each assignment states what to do (with the context needed), what result you expect back and what is out of scope.",
  "Employees see neither the task nor the other employees' answers; pass on what they need.",
  "Each employee remembers your earlier assignments to them in this run; a short follow-up assignment is enough for questions or rework.",
  `You have at most ${maximumDelegations} assignments. Match the effort to the task: a simple task needs one or two assignments, only extensive tasks need more. Do not assign the same work twice; independent assignments may run in parallel.`,
  "Write assignments in the language of the task.",
  "Finish as soon as the task is done. Check first that the result fully meets the task, then fill in every field of the result.",
];

/** Erster Turn des Orchestrators: Rolle, Regeln, Team, Arbeitsordner, Ergebnisform und die Aufgabe. */
export function orchestratorPrompt(options: {
  members: TeamMemberTool[]; fields: TeamworkOutputField[]; instruction: string; mediaUrls: string[];
  workspace?: NodeAttachmentWorkspace; imagePaths: string[];
}): LlmPrompt {
  const attachments = [attachmentsSectionFor(options.workspace), teamworkImageInstructions(options.imagePaths)];
  return orchestratorRules.reduce((builder, rule) => builder.rule(rule), PromptBuilder.create())
    .role("You lead a team of employees and complete the task in <task> together with them.")
    .attachments(attachments.filter(Boolean).join("\n\n"))
    .reference("team", options.members.map((member) =>
      `- ${member.toolName}: ${member.employeeName} – ${member.responsibility}`).join("\n"))
    .reference("workspace", workspaceHint())
    .outputFormat(fileFieldsHint(options.fields) ?? "Fill in every field of the result.")
    .responseLanguage(sameAsTask)
    .task(options.instruction)
    .media(options.mediaUrls)
    .build();
}

/** Folgeturn nach einer Beanstandung; der Systemteil steckt schon im fortgesetzten Gespräch. */
export function revisionPrompt(findings: string): LlmPrompt {
  return PromptBuilder.create()
    .task("The review rejected the result. Fix the issues in <context name=\"findings\">, with follow-up assignments to the employees if needed, and deliver the complete result again.")
    .context("findings", findings)
    .build();
}

/** Systemteil eines Mitarbeiters für das ganze Gespräch eines Laufs. */
export function memberSystemPrompt(employee: ResolvedEmployee): string | undefined {
  const role = [
    "You are a member of a team. The team lead gives you assignments in <task>, with the expected result and its scope as <context>.",
    "Carry out each assignment and answer with your result as text.",
  ].join(" ");
  return renderer.render(PromptBuilder.create()
    .role(roleWithEmployee(role, employee))
    .employee(employee.name, employee.constraint)
    .reference("workspace", workspaceHint())
    .responseLanguage(sameAsTask)
    .build()).system;
}

/** Der Auftrag an einen Mitarbeiter als Nutzernachricht seines Gesprächs. */
export function memberTaskPrompt({task, expectedResult, boundaries}: TeamworkTask): string {
  return renderer.render(PromptBuilder.create()
    .task(task)
    .context("expected_result", expectedResult)
    .context("boundaries", boundaries ?? "")
    .build()).user;
}
