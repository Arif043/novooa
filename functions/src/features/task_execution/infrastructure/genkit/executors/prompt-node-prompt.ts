import {type LlmPrompt} from "../../../../language_models/domain/prompting/llm-prompt.js";
import {PromptBuilder} from "../../../../language_models/domain/prompting/prompt-builder.js";
import {sameAsTask} from "../../../../language_models/domain/prompting/response-language.js";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {type PromptNodeInput} from "./prompt-node-types.js";
import {attachmentsSectionFor, roleWithEmployee} from "./workflow-prompt-sections.js";

const baseRole = [
  "You carry out one step of an automated workflow.",
  "Complete the task in <task> and return only the result, without introduction or closing remarks.",
].join(" ");

/**
 * Prompt eines Prompt-Bausteins. Feste Texte sind englisch, die Antwort folgt der Sprache der
 * Anweisung. Die Anweisung selbst bleibt wörtlich; Bilder gehen als Medienteile mit.
 */
export function promptNodePrompt(input: PromptNodeInput, workspace?: NodeAttachmentWorkspace): LlmPrompt {
  return PromptBuilder.create()
    .role(roleWithEmployee(baseRole, input.employee))
    .employee(input.employee?.name, input.employee?.constraint)
    .attachments(attachmentsSectionFor(workspace))
    .outputFormat(outputFormatFor(input))
    .responseLanguage(sameAsTask)
    .task(input.instruction)
    .media(input.mediaUrls)
    .build();
}

/** Nur ein kurzer Hinweis — das Schema geht über die Ausgabeart an das Modell. */
function outputFormatFor(input: PromptNodeInput): string | undefined {
  if (input.outputType === "decision") return `Answer with exactly one of these options: ${input.choices.join(", ")}.`;
  if (input.outputType === "structured") return "Fill in every field of the structured output.";
  return undefined;
}
