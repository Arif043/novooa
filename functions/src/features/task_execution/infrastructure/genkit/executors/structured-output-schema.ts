import {z} from "genkit";
import {type NodeOutputValue, primitiveNodeOutputValue} from "../../../domain/entities/workflow-value.js";
import {ModelOutputSchemaError} from "../../../../language_models/infrastructure/errors/language-model-errors.js";
import {type StructuredOutputField} from "./prompt-node-types.js";

export type StructuredFieldValue = string | number | boolean;

/** Das Ausgabeschema einer strukturierten Ausgabe aus den Feldern des Bausteins. */
export function structuredSchemaFor(fields: StructuredOutputField[]) {
  const shape = fields.reduce<Record<string, z.ZodTypeAny>>((schema, field) => {
    schema[field.name.trim()] = fieldSchemaFor(field);
    return schema;
  }, {});
  return z.object(shape);
}

/** Schema eines Felds samt Beschreibung; Typen, die das Modell als Text liefert, bekommen einen Formathinweis. */
export function fieldSchemaFor(field: Pick<StructuredOutputField, "type" | "description">): z.ZodTypeAny {
  const description = [field.description.trim(), formatHintFor(field.type)].filter(Boolean).join(" ");
  const base = baseSchemaFor(field.type);
  return description.length === 0 ? base : base.describe(description);
}

// `number`/`boolean` nutzen Zods Coercion (Genkits eigene Empfehlung für
// robuste strukturierte Ausgaben), da Modelle Zahlen/Wahrheitswerte
// gelegentlich als String statt als natives JSON liefern. JSON kommt als Text,
// weil freie Objekte in den Ausgabeschemas der Anbieter nicht überall erlaubt sind.
function baseSchemaFor(type: StructuredOutputField["type"]): z.ZodTypeAny {
  switch (type) {
    case "number": return z.coerce.number();
    case "boolean": return z.coerce.boolean();
    case "datetime": return z.string().refine(isDateTime, "Erwartet Datum und Uhrzeit nach ISO 8601.");
    default: return z.string().min(1);
  }
}

function formatHintFor(type: StructuredOutputField["type"]): string {
  if (type === "datetime") return "Datum und Uhrzeit nach ISO 8601, z. B. 2026-10-18T09:30:00.";
  if (type === "json") return "Gültiges JSON als Text.";
  return "";
}

/** Typisierte Workflow-Werte der definierten Felder; ungültiges JSON ist ein Schemafehler des Modells. */
export function fieldOutputsFor(
  output: Record<string, unknown>, fields: Array<Pick<StructuredOutputField, "name" | "type">>,
): Record<string, NodeOutputValue> {
  const outputs: Record<string, NodeOutputValue> = {};
  for (const field of fields) {
    const name = field.name.trim();
    if (name in output) outputs[name] = valueFor(name, field.type, output[name]);
  }
  return outputs;
}

function valueFor(name: string, type: StructuredOutputField["type"], value: unknown): NodeOutputValue {
  if (type === "datetime") return {type: "datetime", value: String(value)};
  if (type === "json") return {type: "json", value: parsedJson(name, value)};
  return primitiveNodeOutputValue(value as StructuredFieldValue);
}

function parsedJson(name: string, value: unknown): unknown {
  if (typeof value !== "string") return value;
  try {
    return JSON.parse(value) as unknown;
  } catch {
    throw new ModelOutputSchemaError(`Das Feld „${name}“ enthält kein gültiges JSON: ${value.slice(0, 200)}`);
  }
}

function isDateTime(value: string): boolean {
  return /^\d{4}-\d{2}-\d{2}(T\d{2}:\d{2}(:\d{2}(\.\d+)?)?(Z|[+-]\d{2}:?\d{2})?)?$/.test(value.trim()) &&
    !Number.isNaN(Date.parse(value));
}

/** Nur die im Baustein definierten Felder; zusätzliche Felder des Modells fallen weg. */
export function definedFieldsOf<T>(
  output: Record<string, T>, fields: Array<Pick<StructuredOutputField, "name">>,
): Record<string, T> {
  return fields.reduce<Record<string, T>>((defined, field) => {
    const name = field.name.trim();
    return name in output ? {...defined, [name]: output[name]} : defined;
  }, {});
}
