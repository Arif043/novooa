import {type TeamworkOutputField} from "../../../../domain/entities/teamwork-config.js";
import {type LlmStructuredField} from "../../../../../language_models/domain/prompting/llm-gateway.js";
import {sharedDirectoryName} from "../../runner/teamwork-workspace.js";

/** Felder mit Namen; leere Zeilen aus dem Editor zählen nicht. */
export function namedOutputFields(fields: TeamworkOutputField[]): TeamworkOutputField[] {
  return fields.filter((field) => field.name.trim().length > 0);
}

/** Felder des Endergebnisses: Werte wie beim Prompt-Baustein, Datei-Felder als Pfad im Arbeitsordner. */
export function teamworkResultFields(fields: TeamworkOutputField[]): LlmStructuredField[] {
  return fields.map((field) => field.type === "file"
    ? {name: field.name, type: "string", description: fileFieldDescription(field)}
    : {name: field.name, type: field.type, description: field.description});
}

function fileFieldDescription(field: Extract<TeamworkOutputField, {type: "file"}>): string {
  const example = `${sharedDirectoryName}/${field.name.trim()}${extensionFor(field.fileFormat)}`;
  const hint = `Path of the result file under ${sharedDirectoryName}/, e.g. ${example}.`;
  return [field.description.trim(), hint].filter(Boolean).join(" ");
}

export function extensionFor(format: Extract<TeamworkOutputField, {type: "file"}>["fileFormat"]): string {
  return {markdown: ".md", csv: ".csv", json: ".json", text: ".txt"}[format];
}
