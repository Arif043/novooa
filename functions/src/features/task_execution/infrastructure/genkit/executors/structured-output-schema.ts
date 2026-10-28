import {type NodeOutputValue, primitiveNodeOutputValue} from "../../../domain/entities/workflow-value.js";
import {ModelOutputSchemaError} from "../../../../language_models/infrastructure/errors/language-model-errors.js";
import {type StructuredOutputField} from "./prompt-node-types.js";

export type StructuredFieldValue = string | number | boolean;

// Schema-Aufbau liegt im LLM-Framework; hier nur die Umwandlung der Modellausgabe in Workflow-Werte.
export {fieldSchemaFor, structuredSchemaFor} from "../../../../language_models/infrastructure/genkit/llm/llm-output-schema.js";

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


/** Nur die im Baustein definierten Felder; zusätzliche Felder des Modells fallen weg. */
export function definedFieldsOf<T>(
  output: Record<string, T>, fields: Array<Pick<StructuredOutputField, "name">>,
): Record<string, T> {
  return fields.reduce<Record<string, T>>((defined, field) => {
    const name = field.name.trim();
    return name in output ? {...defined, [name]: output[name]} : defined;
  }, {});
}
