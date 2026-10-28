import {z} from "genkit";
import {type LlmStructuredField} from "../../../domain/prompting/llm-gateway.js";

/** Das Ausgabeschema einer strukturierten Ausgabe aus ihren Feldern. */
export function structuredSchemaFor(fields: readonly LlmStructuredField[]) {
  const shape = fields.reduce<Record<string, z.ZodTypeAny>>((schema, field) => {
    schema[field.name.trim()] = fieldSchemaFor(field);
    return schema;
  }, {});
  return z.object(shape);
}

/** Schema der Auswahl: genau eine der Optionen im Feld `answer`. */
export function choiceSchemaFor(choices: readonly string[]) {
  return z.object({answer: z.enum(choices as [string, ...string[]])});
}

/**
 * Schema eines Felds samt Beschreibung; Typen, die das Modell als Text liefert, bekommen einen
 * Formathinweis. Beschreibungen gehen ans Modell und sind deshalb englisch.
 */
export function fieldSchemaFor(field: Pick<LlmStructuredField, "type" | "description" | "allowEmpty">): z.ZodTypeAny {
  const description = [field.description.trim(), formatHintFor(field.type)].filter(Boolean).join(" ");
  const base = field.allowEmpty && field.type === "string" ? z.string() : baseSchemaFor(field.type);
  return description.length === 0 ? base : base.describe(description);
}

// `number`/`boolean` nutzen Zods Coercion (Genkits eigene Empfehlung für
// robuste strukturierte Ausgaben), da Modelle Zahlen/Wahrheitswerte
// gelegentlich als String statt als natives JSON liefern. JSON kommt als Text,
// weil freie Objekte in den Ausgabeschemas der Anbieter nicht überall erlaubt sind.
function baseSchemaFor(type: LlmStructuredField["type"]): z.ZodTypeAny {
  switch (type) {
    case "number": return z.coerce.number();
    case "boolean": return z.coerce.boolean();
    // Die Meldung sieht der Nutzer im Fehlerfall; sie bleibt deshalb deutsch.
    case "datetime": return z.string().refine(isDateTime, "Erwartet Datum und Uhrzeit nach ISO 8601.");
    default: return z.string().min(1);
  }
}

function formatHintFor(type: LlmStructuredField["type"]): string {
  if (type === "datetime") return "Date and time in ISO 8601, e.g. 2026-10-18T09:30:00.";
  if (type === "json") return "Valid JSON as text.";
  return "";
}

function isDateTime(value: string): boolean {
  return /^\d{4}-\d{2}-\d{2}(T\d{2}:\d{2}(:\d{2}(\.\d+)?)?(Z|[+-]\d{2}:?\d{2})?)?$/.test(value.trim()) &&
    !Number.isNaN(Date.parse(value));
}
