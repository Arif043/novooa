import {type TeamworkOutputField} from "../../../../domain/entities/teamwork-config.js";
import {type LlmStructuredField} from "../../../../../language_models/domain/prompting/llm-gateway.js";
import {type LlmPrompt} from "../../../../../language_models/domain/prompting/llm-prompt.js";
import {PromptBuilder} from "../../../../../language_models/domain/prompting/prompt-builder.js";
import {sameAsTask} from "../../../../../language_models/domain/prompting/response-language.js";
import {sharedDirectoryName} from "../../runner/teamwork-workspace.js";

/** Höchstens so oft bessert der Orchestrator nach einer Beanstandung nach. */
export const maximumRevisions = 2;

/** Das Urteil der Prüfung als Felder der strukturierten Ausgabe. */
export const verdictFields: LlmStructuredField[] = [
  {name: "approved", type: "boolean", description: "true if the result can be delivered without defects."},
  {name: "findings", type: "string", allowEmpty: true, description: "The defects, concrete and fixable; empty if approved."},
];

/** Die Prüfung: kritisch, konkret, ohne selbst nachzubessern; die Anweisung bestimmt die Antwortsprache. */
export function reviewPrompt(instruction: string, fields: TeamworkOutputField[], result: Record<string, unknown>): LlmPrompt {
  return PromptBuilder.create()
    .role([
      "You critically review a team's result before it is delivered.",
      "<task> contains the instruction given to the team, <context name=\"result_fields\"> describes the fields and <context name=\"result\"> holds the result.",
    ].join(" "))
    .rule("Check whether the result fully and correctly fulfils the instruction, whether every field matches its description and whether the details are consistent.")
    .rule("Report only real defects, not matters of taste. Name every defect concretely so it can be fixed. If everything is fine, approve the result and leave findings empty.")
    .reference("workspace", `You can read result files, attachments and intermediate results with list_files and read_file; result files are under ${sharedDirectoryName}/.`)
    .responseLanguage(sameAsTask)
    .task(instruction)
    .context("result_fields", fields.map(fieldLine).join("\n"))
    .context("result", JSON.stringify(result, null, 2))
    .build();
}

function fieldLine(field: TeamworkOutputField): string {
  const kind = field.type === "file" ? `file (${field.fileFormat})` : field.type;
  const description = field.description.trim();
  return `- ${field.name.trim()} (${kind})${description ? `: ${description}` : ""}`;
}
