import {z} from "genkit";
import {type TeamworkOutputField} from "../../../../domain/entities/teamwork-config.js";
import {sharedDirectoryName} from "../../runner/teamwork-workspace.js";
import {fieldSchemaFor} from "../structured-output-schema.js";

/** Felder mit Namen; leere Zeilen aus dem Editor zählen nicht. */
export function namedOutputFields(fields: TeamworkOutputField[]): TeamworkOutputField[] {
  return fields.filter((field) => field.name.trim().length > 0);
}

/** Schema des Endergebnisses: Werte wie beim Prompt-Baustein, Datei-Felder als Pfad im Arbeitsordner. */
export function teamworkSchemaFor(fields: TeamworkOutputField[]) {
  const shape: Record<string, z.ZodTypeAny> = {};
  for (const field of fields) {
    shape[field.name.trim()] = field.type === "file" ? fileFieldSchemaFor(field) : fieldSchemaFor(field);
  }
  return z.object(shape);
}

function fileFieldSchemaFor(field: Extract<TeamworkOutputField, {type: "file"}>): z.ZodTypeAny {
  const hint = `Pfad der Ergebnisdatei unter ${sharedDirectoryName}/, z. B. ${sharedDirectoryName}/${field.name.trim()}${extensionFor(field.fileFormat)}.`;
  return z.string().min(1).describe([field.description.trim(), hint].filter(Boolean).join(" "));
}

export function extensionFor(format: Extract<TeamworkOutputField, {type: "file"}>["fileFormat"]): string {
  return {markdown: ".md", csv: ".csv", json: ".json", text: ".txt"}[format];
}
