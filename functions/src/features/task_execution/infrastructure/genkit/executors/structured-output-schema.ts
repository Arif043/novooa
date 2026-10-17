import {z} from "genkit";
import {primitiveNodeOutputValue} from "../../../domain/entities/workflow-value.js";
import {type StructuredOutputField} from "./prompt-node-types.js";

export type StructuredFieldValue = string | number | boolean;

/** Das Ausgabeschema einer strukturierten Prompt-Ausgabe aus den Feldern des Bausteins. */
export function structuredSchemaFor(fields: StructuredOutputField[]) {
  const shape = fields.reduce<Record<string, z.ZodTypeAny>>((schema, field) => {
    schema[field.name.trim()] = fieldSchemaFor(field);
    return schema;
  }, {});
  return z.object(shape);
}

// `number`/`boolean` nutzen Zods Coercion (Genkits eigene Empfehlung für
// robuste strukturierte Ausgaben), da Modelle Zahlen/Wahrheitswerte
// gelegentlich als String statt als natives JSON liefern.
function fieldSchemaFor(field: StructuredOutputField): z.ZodTypeAny {
  const description = field.description.trim();
  const base = baseSchemaFor(field.type);
  return description.length === 0 ? base : base.describe(description);
}

function baseSchemaFor(type: StructuredOutputField["type"]): z.ZodTypeAny {
  switch (type) {
    case "number": return z.coerce.number();
    case "boolean": return z.coerce.boolean();
    default: return z.string().min(1);
  }
}

export function fieldOutputsFor(output: Record<string, StructuredFieldValue>) {
  return Object.entries(output).reduce<Record<string, ReturnType<typeof primitiveNodeOutputValue>>>(
    (outputs, [key, value]) => ({...outputs, [key]: primitiveNodeOutputValue(value)}),
    {},
  );
}

/** Nur die im Baustein definierten Felder; zusätzliche Felder des Modells fallen weg. */
export function definedFieldsOf(
  output: Record<string, StructuredFieldValue>, fields: StructuredOutputField[],
): Record<string, StructuredFieldValue> {
  return fields.reduce<Record<string, StructuredFieldValue>>((defined, field) => {
    const name = field.name.trim();
    return name in output ? {...defined, [name]: output[name]} : defined;
  }, {});
}
