import {type TeamworkOutputField} from "../../../../domain/entities/teamwork-config.js";
import {sharedDirectoryName} from "../../runner/teamwork-workspace.js";

/** Höchstens so viele Aufträge vergibt der Orchestrator in einem Lauf. */
export const maximumDelegations = 10;

export type TeamMemberTool = {toolName: string; employeeName: string; responsibility: string};

const fileFormatNames: Record<string, string> = {
  markdown: "Markdown (.md)", csv: "CSV-Tabelle (.csv)", json: "JSON (.json)", text: "Text (.txt)",
};

/** System-Prompt des Orchestrators: Rolle, Team, Arbeitsordner und wie das Endergebnis aussieht. */
export function orchestratorSystemPrompt(members: TeamMemberTool[], fields: TeamworkOutputField[]): string {
  return [
    "Du leitest ein Team aus Mitarbeitern und erledigst die Aufgabe gemeinsam mit ihnen.",
    "Vergib Teilaufgaben über die Werkzeuge delegate_to_…. Jeder Auftrag muss für sich verständlich sein: " +
      "Nenne Ziel, nötigen Kontext und erwartetes Ergebnis. Mitarbeiter sehen weder die Aufgabe noch die " +
      "Antworten der anderen; gib weiter, was sie davon brauchen.",
    `Du hast höchstens ${maximumDelegations} Aufträge. Unabhängige Aufträge darfst du gleichzeitig vergeben.`,
    `Team:\n${members.map((member) => `- ${member.toolName}: ${member.employeeName} – ${member.responsibility}`).join("\n")}`,
    workspaceHint(),
    fileFieldHint(fields),
    "Fülle am Ende alle Felder des Ergebnisses aus.",
  ].filter((part) => part.length > 0).join("\n\n");
}

/** Der Auftrag an einen Mitarbeiter, ergänzt um den Arbeitsordner. */
export function memberTaskPrompt(task: string): string {
  return [task.trim(), workspaceHint(), "Antworte mit deinem Ergebnis als Text."].join("\n\n");
}

function workspaceHint(): string {
  return [
    "Arbeitsordner (Werkzeuge list_files, read_file, write_file):",
    "- Angehängte Dateien und Wissensnotizen liegen im Wurzelordner und unter knowledge/.",
    `- ${sharedDirectoryName}/ ist die gemeinsame Ablage des Teams. Lege längere Zwischenergebnisse dort als ` +
      "Datei ab und nenne den Pfad, statt sie vollständig zu wiederholen.",
  ].join("\n");
}

function fileFieldHint(fields: TeamworkOutputField[]): string {
  const files = fields.filter((field) => field.type === "file");
  if (files.length === 0) return "";
  return [
    `Für Datei-Felder schreibst du (oder ein Mitarbeiter) die Datei unter ${sharedDirectoryName}/ und trägst ihren Pfad ein:`,
    ...files.map((field) => `- ${field.name.trim()}: ${fileFormatNames[field.fileFormat]}`),
  ].join("\n");
}
