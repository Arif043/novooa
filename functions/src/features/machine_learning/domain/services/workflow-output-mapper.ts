import {type TransformationParameter} from "../entities/model-contract.js";
import {type ModelOutputValue} from "../entities/model-output-value.js";

export function mapWorkflowOutput(
  mapping: TransformationParameter,
  values: ReadonlyMap<string, ModelOutputValue>,
): ModelOutputValue {
  return mappedValue(mapping, values);
}

function mappedValue(
  mapping: TransformationParameter,
  values: ReadonlyMap<string, ModelOutputValue>,
  item?: ModelOutputValue,
): ModelOutputValue {
  if (typeof mapping === "string") return referenceValue(mapping, values, item);
  if (typeof mapping === "number" || typeof mapping === "boolean") return mapping;
  if (Array.isArray(mapping)) return mapping.map((value) => mappedValue(value, values, item));
  if ("$map" in mapping) return mappedArray(mapping.$map, values);
  if ("$lookup" in mapping) return lookupValue(mapping.$lookup, values, item);
  return Object.fromEntries(Object.entries(mapping).map(([key, value]) => [key, mappedValue(value, values, item)]));
}

function mappedArray(value: TransformationParameter, values: ReadonlyMap<string, ModelOutputValue>): ModelOutputValue {
  if (!isRecord(value) || typeof value.from !== "string" || value.item === undefined) {
    throw new Error("$map benötigt from und item.");
  }
  const source = values.get(value.from);
  if (!Array.isArray(source)) throw new Error(`Das Transformations-Ergebnis ${value.from} ist keine Liste.`);
  return source.map((item) => mappedValue(value.item!, values, item));
}

function lookupValue(
  value: TransformationParameter,
  values: ReadonlyMap<string, ModelOutputValue>,
  item: ModelOutputValue | undefined,
): ModelOutputValue {
  if (!isRecord(value) || !Array.isArray(value.values) || value.key === undefined) {
    throw new Error("$lookup benötigt values und key.");
  }
  const index = mappedValue(value.key, values, item);
  if (typeof index !== "number" || !Number.isSafeInteger(index) || index < 0 || index >= value.values.length) {
    throw new Error("$lookup erhielt keinen gültigen Index.");
  }
  return mappedValue(value.values[index]!, values, item);
}

function referenceValue(value: string, values: ReadonlyMap<string, ModelOutputValue>, item?: ModelOutputValue): ModelOutputValue {
  if (!value.startsWith("$")) return value;
  const [name, ...path] = value.slice(1).split(".");
  return valueAtPath(name === "item" ? item : values.get(name!), path);
}

function valueAtPath(value: ModelOutputValue | undefined, path: readonly string[]): ModelOutputValue {
  if (value === undefined) throw new Error("Die Referenz im Workflow-Mapping ist unbekannt.");
  if (path.length === 0) return value;
  const [segment, ...remaining] = path;
  if (Array.isArray(value) && /^\d+$/.test(segment!)) return valueAtPath(value[Number(segment)], remaining);
  if (isRecord(value) && segment! in value) return valueAtPath(value[segment!]!, remaining);
  throw new Error("Die Referenz im Workflow-Mapping ist ungültig.");
}

function isRecord(value: unknown): value is Readonly<Record<string, TransformationParameter>> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
