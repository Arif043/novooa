import {type ModelInputValue} from "../domain/entities/model-input-source.js";
import {type ModelTensor} from "../domain/entities/model-tensor.js";
import {
  type ModelInferenceOutput,
  type ModelInferenceRequest,
  type ModelInferenceResult,
} from "../domain/repositories/model-inference.js";
import {modelTensorFromJson, modelTensorToJson} from "./local/model-tensor-json-codec.js";

export function modelInferenceRequestJson(request: ModelInferenceRequest) {
  return {
    teamId: request.teamId,
    modelId: request.modelId,
    inputs: request.inputs.map(inputJson),
  };
}

export function modelInferenceRequestFromJson(value: unknown): ModelInferenceRequest {
  const data = objectFrom(value, "Die Inferenzanfrage ist ungültig.");
  return {
    teamId: requiredString(data.teamId, "Die Team-ID fehlt."),
    modelId: requiredString(data.modelId, "Die Modell-ID fehlt."),
    inputs: inputsFrom(data.inputs),
  };
}

export function modelInferenceResultJson(result: ModelInferenceResult) {
  return {
    modelId: result.modelId,
    outputs: result.outputs.map((output) => ({
      ...modelTensorToJson(output),
      semantic: output.semantic,
    })),
  };
}

export function modelInferenceResultFromJson(value: unknown): ModelInferenceResult {
  const data = objectFrom(value, "Die Inferenzantwort ist ungültig.");
  if (!Array.isArray(data.outputs)) throw new Error("Die Inferenzantwort enthält keine Ausgaben.");
  return {
    modelId: requiredString(data.modelId, "Die Modell-ID der Inferenzantwort fehlt."),
    outputs: data.outputs.map(outputFrom),
  };
}

function inputJson(input: ModelInputValue) {
  switch (input.type) {
    case "image":
    case "file":
      return binaryInputJson(input);
    case "tensor":
      return {type: input.type, tensor: modelTensorToJson(input.tensor)};
    default:
      return input;
  }
}

function binaryInputJson(input: Extract<ModelInputValue, {bytes: Uint8Array}>) {
  const {bytes, ...metadata} = input;
  return {...metadata, dataBase64: Buffer.from(bytes).toString("base64")};
}

function outputFrom(value: unknown): ModelInferenceOutput {
  const data = objectFrom(value, "Eine Inferenz-Ausgabe ist ungültig.");
  const tensor = modelTensorFromJson(data);
  return {...tensor, semantic: requiredString(data.semantic, "Die Ausgabe-Semantik fehlt.")};
}

function inputsFrom(value: unknown): readonly ModelInputValue[] {
  if (!Array.isArray(value)) throw new Error("Die Modelleingaben fehlen.");
  return value.map(inputFrom);
}

function inputFrom(value: unknown): ModelInputValue {
  const data = objectFrom(value, "Eine Modelleingabe ist ungültig.");
  const type = requiredString(data.type, "Der Typ der Modelleingabe fehlt.");
  return inputForType(type, data);
}

function inputForType(type: string, data: Record<string, unknown>): ModelInputValue {
  switch (type) {
    case "image":
    case "file":
      return binaryInput(type, data);
    case "text":
    case "datetime":
      return {type, value: requiredString(data.value, "Der Eingabewert fehlt.")};
    case "number":
      return {type, value: finiteNumber(data.value)};
    case "boolean":
      return {type, value: booleanFrom(data.value)};
    case "json":
      return {type, value: data.value};
    case "tensor":
      return {type, tensor: tensorFrom(data.tensor)};
    default:
      throw new Error("Der Typ der Modelleingabe wird nicht unterstützt.");
  }
}

function binaryInput(type: "image" | "file", data: Record<string, unknown>) {
  return {
    type,
    contentType: requiredString(data.contentType, "Der Content-Type fehlt."),
    bytes: bytesFrom(data.dataBase64),
  };
}

function tensorFrom(value: unknown): ModelTensor {
  return modelTensorFromJson(value);
}

function bytesFrom(value: unknown): Uint8Array {
  if (typeof value !== "string" || !validBase64(value)) {
    throw new Error("Die Binärdaten der Modelleingabe sind ungültig.");
  }
  return Uint8Array.from(Buffer.from(value, "base64"));
}

function validBase64(value: string): boolean {
  return value.length > 0 && value.length % 4 === 0 && /^[A-Za-z0-9+/]*={0,2}$/.test(value);
}

function finiteNumber(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new Error("Die Zahl der Modelleingabe ist ungültig.");
  }
  return value;
}

function booleanFrom(value: unknown): boolean {
  if (typeof value !== "boolean") throw new Error("Der Boolean-Wert der Modelleingabe ist ungültig.");
  return value;
}

function objectFrom(value: unknown, message: string): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) throw new Error(message);
  return value as Record<string, unknown>;
}

function requiredString(value: unknown, message: string): string {
  if (typeof value !== "string" || value.trim().length === 0) throw new Error(message);
  return value;
}
