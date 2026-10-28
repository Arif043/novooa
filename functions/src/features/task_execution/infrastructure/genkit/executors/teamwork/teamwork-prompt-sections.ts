import {type TeamworkOutputField} from "../../../../domain/entities/teamwork-config.js";
import {sharedDirectoryName} from "../../runner/teamwork-workspace.js";

const fileFormatNames: Record<string, string> = {
  markdown: "Markdown (.md)", csv: "CSV table (.csv)", json: "JSON (.json)", text: "Text (.txt)",
};

/** Arbeitsordner des Teams — gleicher Wortlaut für Orchestrator und Mitarbeiter. */
export function workspaceHint(): string {
  return [
    "Working folder (tools list_files, read_file, write_file):",
    "- Attached files and knowledge notes are in the root folder and under knowledge/.",
    `- ${sharedDirectoryName}/ is the team's shared storage. Save longer intermediate results there as a file and give the path instead of repeating them in full.`,
  ].join("\n");
}

/** Wie Datei-Felder des Ergebnisses entstehen; `undefined` ohne Datei-Felder. */
export function fileFieldsHint(fields: TeamworkOutputField[]): string | undefined {
  const files = fields.filter((field) => field.type === "file");
  if (files.length === 0) return undefined;
  return [
    `Fill in every field of the result. For file fields, you (or an employee) write the file under ${sharedDirectoryName}/ and enter its path:`,
    ...files.map((field) => `- ${field.name.trim()}: ${fileFormatNames[field.fileFormat]}`),
  ].join("\n");
}
