import {
  type ModelTensor,
  validateModelTensor,
} from "../../domain/entities/model-tensor.js";
import {
  modelTensorDataTypes,
  type ModelTensorDataType,
} from "../../domain/entities/model-contract.js";
import {type PythonOnnxWorkerRequest} from "./python-onnx-worker.js";

export function pythonOnnxWorkerInputJson(request: PythonOnnxWorkerRequest): string {
  return JSON.stringify({
    modelBase64: Buffer.from(request.artifact).toString("base64"),
    inputs: request.inputs.map(encodedTensor),
    outputNames: request.outputNames,
  });
}

export function pythonOnnxWorkerOutputFromJson(value: string): readonly ModelTensor[] {
  const data = objectFrom(JSON.parse(value));
  if (!Array.isArray(data.outputs)) throw new Error("Die lokale ONNX-Runtime lieferte keine Tensoren.");
  return data.outputs.map(tensorFrom);
}

function encodedTensor(tensor: ModelTensor) {
  return {
    name: tensor.name,
    dataType: tensor.dataType,
    shape: tensor.shape,
    dataBase64: Buffer.from(tensor.bytes).toString("base64"),
  };
}

function tensorFrom(value: unknown): ModelTensor {
  const data = objectFrom(value);
  const tensor = {
    name: stringFrom(data.name, "Der Tensor-Name fehlt."),
    dataType: dataTypeFrom(data.dataType),
    shape: shapeFrom(data.shape),
    bytes: bytesFrom(data.dataBase64),
  };
  validateModelTensor(tensor);
  return tensor;
}

function objectFrom(value: unknown): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("Die Antwort der lokalen ONNX-Runtime ist ungültig.");
  }
  return value as Record<string, unknown>;
}

function stringFrom(value: unknown, message: string): string {
  if (typeof value !== "string" || value.trim().length === 0) throw new Error(message);
  return value;
}

function dataTypeFrom(value: unknown): ModelTensorDataType {
  if (typeof value !== "string" || !modelTensorDataTypes.includes(value as ModelTensorDataType)) {
    throw new Error("Der Tensor-Datentyp ist ungültig.");
  }
  return value as ModelTensorDataType;
}

function shapeFrom(value: unknown): readonly number[] {
  if (!Array.isArray(value) || !value.every(validDimension)) {
    throw new Error("Die Tensor-Form ist ungültig.");
  }
  return value;
}

function validDimension(value: unknown): value is number {
  return typeof value === "number" && Number.isSafeInteger(value) && value > 0;
}

function bytesFrom(value: unknown): Uint8Array {
  if (typeof value !== "string") throw new Error("Die Tensor-Daten fehlen.");
  return Uint8Array.from(Buffer.from(value, "base64"));
}
