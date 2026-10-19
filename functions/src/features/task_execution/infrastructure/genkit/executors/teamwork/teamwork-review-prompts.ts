import {type TeamworkOutputField} from "../../../../domain/entities/teamwork-config.js";
import {sharedDirectoryName} from "../../runner/teamwork-workspace.js";

/** Höchstens so oft bessert der Orchestrator nach einer Beanstandung nach. */
export const maximumRevisions = 2;

/** System-Prompt der Prüfung: kritisch, konkret, ohne selbst nachzubessern. */
export function reviewerSystemPrompt(): string {
  return [
    "Du prüfst das Ergebnis eines Teams kritisch, bevor es abgegeben wird.",
    "Prüfe, ob das Ergebnis die Anweisung vollständig und korrekt erfüllt, ob jedes Feld zu seiner Beschreibung " +
      "passt und ob die Angaben in sich stimmig sind.",
    `Ergebnisdateien, Anhänge und Zwischenergebnisse kannst du mit list_files und read_file lesen; ` +
      `Ergebnisdateien liegen unter ${sharedDirectoryName}/.`,
    "Beanstande nur echte Mängel, keine Geschmacksfragen. Nenne jeden Mangel konkret, damit er sich beheben " +
      "lässt. Ist alles in Ordnung, gib das Ergebnis frei und lass die Befunde leer.",
  ].join("\n\n");
}

/** Was die Prüfung bekommt: Anweisung, Felder und das Ergebnis. */
export function reviewPrompt(instruction: string, fields: TeamworkOutputField[], result: Record<string, unknown>): string {
  return [
    `Anweisung an das Team:\n${instruction.trim()}`,
    `Felder des Ergebnisses:\n${fields.map(fieldLine).join("\n")}`,
    `Ergebnis:\n${JSON.stringify(result, null, 2)}`,
  ].join("\n\n");
}

/** Auftrag an den Orchestrator nach einer Beanstandung. */
export function revisionPrompt(findings: string): string {
  return [
    `Die Prüfung hat das Ergebnis beanstandet:\n${findings.trim()}`,
    "Behebe die Mängel, bei Bedarf mit Folgeaufträgen an die Mitarbeiter, und liefere das vollständige " +
      "Ergebnis erneut.",
  ].join("\n\n");
}

function fieldLine(field: TeamworkOutputField): string {
  const kind = field.type === "file" ? `Datei (${field.fileFormat})` : field.type;
  const description = field.description.trim();
  return `- ${field.name.trim()} (${kind})${description ? `: ${description}` : ""}`;
}
