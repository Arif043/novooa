import {type TeamworkOutputField} from "../../../../domain/entities/teamwork-config.js";
import {sharedDirectoryName} from "../../runner/teamwork-workspace.js";

/** Höchstens so viele Aufträge vergibt der Orchestrator in einem Lauf. */
export const maximumDelegations = 10;

export type TeamMemberTool = {toolName: string; employeeName: string; responsibility: string};

/** Ein Auftrag des Orchestrators an einen Mitarbeiter. */
export type TeamworkTask = {task: string; expectedResult: string; boundaries?: string};

const fileFormatNames: Record<string, string> = {
  markdown: "Markdown (.md)", csv: "CSV-Tabelle (.csv)", json: "JSON (.json)", text: "Text (.txt)",
};

/** System-Prompt des Orchestrators: Rolle, Team, Arbeitsordner und wie das Endergebnis aussieht. */
export function orchestratorSystemPrompt(members: TeamMemberTool[], fields: TeamworkOutputField[]): string {
  return [
    "Du leitest ein Team aus Mitarbeitern und erledigst die Aufgabe gemeinsam mit ihnen.",
    "Vergib Teilaufgaben über die Werkzeuge delegate_to_…. Jeder Auftrag nennt, was zu tun ist (mit dem nötigen " +
      "Kontext), welches Ergebnis du zurück erwartest und was nicht dazugehört. Mitarbeiter sehen weder die " +
      "Aufgabe noch die Antworten der anderen; gib weiter, was sie davon brauchen.",
    "Jeder Mitarbeiter erinnert sich an deine früheren Aufträge an ihn in diesem Lauf. Für Rückfragen oder " +
      "Nacharbeit genügt ein kurzer Folgeauftrag.",
    `Du hast höchstens ${maximumDelegations} Aufträge. Wähle den Aufwand passend: Eine einfache Aufgabe braucht ` +
      "ein bis zwei Aufträge, nur umfangreiche Aufgaben mehr. Vergib keinen Auftrag doppelt. Unabhängige " +
      "Aufträge darfst du gleichzeitig vergeben.",
    `Team:\n${members.map((member) => `- ${member.toolName}: ${member.employeeName} – ${member.responsibility}`).join("\n")}`,
    workspaceHint(),
    fileFieldHint(fields),
    "Schließe ab, sobald die Anweisung erfüllt ist. Prüfe vorher selbst, ob das Ergebnis die Anweisung " +
      "vollständig erfüllt, und fülle dann alle Felder des Ergebnisses aus.",
  ].filter((part) => part.length > 0).join("\n\n");
}

/** Der Auftrag an einen Mitarbeiter, gegliedert und ergänzt um den Arbeitsordner. */
export function memberTaskPrompt({task, expectedResult, boundaries}: TeamworkTask): string {
  return [
    `Auftrag:\n${task.trim()}`,
    `Erwartetes Ergebnis:\n${expectedResult.trim()}`,
    boundaries?.trim() ? `Grenzen:\n${boundaries.trim()}` : "",
    workspaceHint(),
    "Antworte mit deinem Ergebnis als Text.",
  ].filter((part) => part.length > 0).join("\n\n");
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
