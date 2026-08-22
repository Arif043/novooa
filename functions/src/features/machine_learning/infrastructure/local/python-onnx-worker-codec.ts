import {type ModelTensor} from "../../domain/entities/model-tensor.js";
import {modelTensorFromJson, modelTensorToJson} from "./model-tensor-json-codec.js";
import {type PythonOnnxWorkerRequest} from "./python-onnx-worker.js";

export function pythonOnnxWorkerInputJson(request: PythonOnnxWorkerRequest): string {
  return JSON.stringify({
    modelBase64: Buffer.from(request.artifact).toString("base64"),
    inputs: request.inputs.map(modelTensorToJson),
    outputNames: request.outputNames,
  });
}

export function pythonOnnxWorkerOutputFromJson(value: string): readonly ModelTensor[] {
  const data = objectFrom(JSON.parse(value));
  if (!Array.isArray(data.outputs)) throw new Error("Die lokale ONNX-Runtime lieferte keine Tensoren.");
  return data.outputs.map(modelTensorFromJson);
}

function objectFrom(value: unknown): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("Die Antwort der lokalen ONNX-Runtime ist ungültig.");
  }
  return value as Record<string, unknown>;
}
