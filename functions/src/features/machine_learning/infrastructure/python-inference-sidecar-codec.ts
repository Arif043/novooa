import {type ModelOutputValue} from "../domain/entities/model-output-value.js";
import {type ModelRuntimeOutput} from "../domain/repositories/model-inference-runtime.js";
import {modelTensorFromJson} from "./local/model-tensor-json-codec.js";

export function runtimeOutputsFrom(value: unknown): readonly ModelRuntimeOutput[] {
  if (!isRecord(value) || !Array.isArray(value.outputs)) throw new Error("Der ML-Dienst lieferte keine Ausgaben.");
  return value.outputs.map((output) => {
    const data = recordFrom(output);
    const tensor = modelTensorFromJson(data);
    return {...tensor, tensor, transformationValues: transformationValuesFrom(data.transformationValues)};
  });
}

export function sidecarErrorMessage(value: unknown): string {
  return isRecord(value) && typeof value.error === "string" ? value.error : "Der ML-Dienst ist fehlgeschlagen.";
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function transformationValuesFrom(value: unknown): Readonly<Record<string, ModelOutputValue>> {
  const data = recordFrom(value);
  return Object.fromEntries(Object.entries(data).map(([name, item]) => [name, outputValueFrom(item)]));
}

function outputValueFrom(value: unknown): ModelOutputValue {
  if (typeof value === "string" || typeof value === "boolean") return value;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (Array.isArray(value)) return value.map(outputValueFrom);
  const data = recordFrom(value);
  return Object.fromEntries(Object.entries(data).map(([name, item]) => [name, outputValueFrom(item)]));
}

function recordFrom(value: unknown): Record<string, unknown> {
  if (!isRecord(value)) throw new Error("Die Antwort des ML-Dienstes ist ungültig.");
  return value;
}
