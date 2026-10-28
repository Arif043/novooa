import {type LlmPrompt} from "../../../../language_models/domain/prompting/llm-prompt.js";
import {PromptBuilder} from "../../../../language_models/domain/prompting/prompt-builder.js";
import {sameAsTask} from "../../../../language_models/domain/prompting/response-language.js";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {type PromptNodeInput} from "./prompt-node-types.js";

const baseRole = [
  "You carry out one step of an automated workflow.",
  "Complete the task in <task> and return only the result, without introduction or closing remarks.",
].join(" ");

const employeeRole = "Act as the employee described in <employee> and follow its instructions.";

/**
 * Prompt eines Prompt-Bausteins. Feste Texte sind englisch, die Antwort folgt der Sprache der
 * Anweisung. Die Anweisung selbst bleibt wörtlich; Bilder gehen als Medienteile mit.
 */
export function promptNodePrompt(input: PromptNodeInput, workspace?: NodeAttachmentWorkspace): LlmPrompt {
  return PromptBuilder.create()
    .role(input.employee ? `${baseRole} ${employeeRole}` : baseRole)
    .employee(input.employee?.name, input.employee?.constraint)
    .attachments(attachmentsSection(workspace))
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

/** Welche Anhänge über die Dateisystem-Werkzeuge erreichbar sind und wie man sie liest. */
function attachmentsSection(workspace?: NodeAttachmentWorkspace): string | undefined {
  if (!workspace) return undefined;
  const files = workspace.files.map((file) => `- ${file.filename} (${file.displayName})`);
  const notes = workspace.knowledgeFiles
    .filter((note) => note.isDirectAttachment)
    .map((note) => `- ${note.filename} (${note.title})`);
  return [
    "Attached files and knowledge notes are available through the file system tools. Use list_files and read_file to inspect them when needed.",
    files.length > 0 ? `Available files:\n${files.join("\n")}` : "",
    notes.length > 0 ? knowledgeNotesHint(notes) : "",
    workspace.skillCount > 0 ? "Skills are available through the use_skill tool. Use a suitable skill before you answer." : "",
  ].filter(Boolean).join("\n\n");
}

function knowledgeNotesHint(notes: string[]): string {
  return [
    "Directly attached knowledge notes:",
    ...notes,
    "Use exactly these paths when reading knowledge notes. Linked notes are in the workspace as well: follow the links from the attached note; knowledge/manifest.json lists them all.",
  ].join("\n");
}
