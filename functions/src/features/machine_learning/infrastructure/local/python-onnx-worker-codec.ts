import {type ModelRuntimeOutput} from "../../domain/repositories/model-inference-runtime.js";
import {modelTensorFromJson, modelTensorToJson} from "./model-tensor-json-codec.js";
import {type PythonOnnxWorkerRequest} from "./python-onnx-worker.js";
import {type ModelOutputValue} from "../../domain/entities/model-output-value.js";

export function pythonOnnxWorkerInputJson(request: PythonOnnxWorkerRequest): string {
  return JSON.stringify({
    modelBase64: Buffer.from(request.artifact).toString("base64"),
    inputs: request.inputs.map(modelTensorToJson),
    outputs: request.outputs,
  });
}

export function pythonOnnxWorkerOutputFromJson(value: string): readonly ModelRuntimeOutput[] {
  const data = objectFrom(JSON.parse(value));
  if (!Array.isArray(data.outputs)) throw new Error("Die lokale ONNX-Runtime lieferte keine Ausgaben.");
  return data.outputs.map(outputFrom);
}

function outputFrom(value: unknown): ModelRuntimeOutput {
  const data = objectFrom(value);
  const tensor = modelTensorFromJson(data);
  return {
    ...tensor,
    tensor,
    transformationValues: outputValuesFrom(data.transformationValues),
  };
}

function outputValuesFrom(value: unknown): Readonly<Record<string, ModelOutputValue>> {
  const data = objectFrom(value);
  return Object.fromEntries(Object.entries(data).map(([key, item]) => [key, outputValueFrom(item)]));
}

function outputValueFrom(value: unknown): ModelOutputValue {
  if (typeof value === "string" || typeof value === "boolean") return value;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (Array.isArray(value)) return value.map(outputValueFrom);
  const data = objectFrom(value);
  return Object.fromEntries(Object.entries(data).map(([key, item]) => [key, outputValueFrom(item)]));
}

function objectFrom(value: unknown): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("Die Antwort der lokalen ONNX-Runtime ist ungültig.");
  }
  return value as Record<string, unknown>;
}
