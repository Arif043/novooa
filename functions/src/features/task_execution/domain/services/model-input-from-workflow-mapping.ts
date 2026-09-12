import {
  type ModelInputValue,
} from "../../../machine_learning/domain/entities/model-input-source.js";
import {
  type ModelTensor,
} from "../../../machine_learning/domain/entities/model-tensor.js";
import {
  type TeamFileContentReader,
} from "../../../files/domain/repositories/team-file-content-reader.js";
import {
  type ModelInferenceInputMapping,
} from "../entities/task.js";

export async function modelInputFromWorkflowMapping(
  mapping: ModelInferenceInputMapping,
  value: unknown,
  teamId: string,
  fileContentReader: TeamFileContentReader,
): Promise<ModelInputValue> {
  switch (mapping.sourceType) {
    case "image":
    case "file":
      return fileInput(mapping.sourceType, value, teamId, fileContentReader);
    case "text": return {type: "text", value: textValue(value)};
    case "datetime": return {type: "datetime", value: textValue(value)};
    case "number": return {type: "number", value: numberValue(value)};
    case "boolean": return {type: "boolean", value: booleanValue(value)};
    case "json": return {type: "json", value: jsonValue(value)};
    case "tensor": return {type: "tensor", tensor: tensorFor(mapping, value)};
  }
}

async function fileInput(
  type: "image" | "file",
  value: unknown,
  teamId: string,
  reader: TeamFileContentReader,
): Promise<ModelInputValue> {
  const reference = fileReference(value);
  const content = await reader.readTeamFileContent(
    teamId, reference.fileId, reference.versionId,
  );
  if (type === "image" && !content.contentType.startsWith("image/")) {
    throw new Error("Die Modelleingabe erwartet ein Bild.");
  }
  return {type, contentType: content.contentType, bytes: content.content};
}

function fileReference(value: unknown): {fileId: string; versionId: string} {
  if (!isRecord(value) || typeof value.fileId !== "string" || typeof value.versionId !== "string") {
    throw new Error("Die Modelleingabe erwartet eine Datei- oder Medienvariable.");
  }
  return {fileId: value.fileId, versionId: value.versionId};
}

function textValue(value: unknown): string {
  if (typeof value === "string") return value;
  return JSON.stringify(value);
}

function numberValue(value: unknown): number {
  const number = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(number)) throw new Error("Die Modelleingabe erwartet eine Zahl.");
  return number;
}

function booleanValue(value: unknown): boolean {
  if (typeof value === "boolean") return value;
  if (value === "true") return true;
  if (value === "false") return false;
  throw new Error("Die Modelleingabe erwartet einen Wahrheitswert.");
}

function jsonValue(value: unknown): unknown {
  if (typeof value !== "string") return value;
  try {
    return JSON.parse(value) as unknown;
  } catch {
    throw new Error("Die Modelleingabe erwartet gültiges JSON.");
  }
}

function tensorFor(mapping: ModelInferenceInputMapping, value: unknown): ModelTensor {
  const serialized = serializedTensor(mapping.modelInputName, value);
  if (serialized !== undefined) return serialized;
  const values = numericValues(jsonValue(value));
  const shape = shapeFor(mapping, values.length);
  if (elementCount(shape) !== values.length) {
    throw new Error(`Die Tensorwerte für ${mapping.modelInputName} passen nicht zur Tensor-Form.`);
  }
  return {
    name: mapping.modelInputName,
    dataType: mapping.dataType,
    shape,
    bytes: bytesFor(mapping.dataType, values),
  };
}

function serializedTensor(name: string, value: unknown): ModelTensor | undefined {
  if (!isRecord(value) || typeof value.dataBase64 !== "string") return undefined;
  const dataType = tensorDataType(value.dataType);
  const shape = tensorShape(value.shape);
  return {
    name,
    dataType,
    shape,
    bytes: Uint8Array.from(Buffer.from(value.dataBase64, "base64")),
  };
}

function tensorDataType(value: unknown): ModelInferenceInputMapping["dataType"] {
  if (typeof value !== "string" || !(value in bytesPerElement)) {
    throw new Error("Der Tensor-Ausgang enthält keinen unterstützten Datentyp.");
  }
  return value as ModelInferenceInputMapping["dataType"];
}

function tensorShape(value: unknown): number[] {
  if (!Array.isArray(value) || !value.every((dimension) => Number.isSafeInteger(dimension) && dimension > 0)) {
    throw new Error("Der Tensor-Ausgang enthält eine ungültige Form.");
  }
  return value;
}

function numericValues(value: unknown): number[] {
  if (typeof value === "number") return [numberValue(value)];
  if (!Array.isArray(value)) throw new Error("Die Modelleingabe erwartet Zahlen oder ein Zahlen-Array.");
  return value.flatMap(numericValues);
}

function shapeFor(mapping: ModelInferenceInputMapping, length: number): number[] {
  const dynamicCount = mapping.shape.filter((value) => value === "dynamic").length;
  if (dynamicCount > 1) throw new Error("Die Tensor-Form enthält zu viele dynamische Dimensionen.");
  const fixed = mapping.shape.filter((value): value is number => typeof value === "number");
  if (dynamicCount === 0) return fixed;
  const fixedCount = elementCount(fixed);
  if (length % fixedCount !== 0) throw new Error("Die Tensor-Form passt nicht zum Workflow-Wert.");
  return mapping.shape.map((value) => value === "dynamic" ? length / fixedCount : value);
}

function elementCount(shape: readonly number[]): number {
  return shape.reduce((count, dimension) => count * dimension, 1);
}

function bytesFor(
  dataType: ModelInferenceInputMapping["dataType"],
  values: readonly number[],
): Uint8Array {
  const bytes = new Uint8Array(values.length * bytesPerElement[dataType]);
  const view = new DataView(bytes.buffer);
  values.forEach((value, index) => writeValue(view, dataType, index, value));
  return bytes;
}

const bytesPerElement = {
  float32: 4, float64: 8, int64: 8, int32: 4,
  int16: 2, int8: 1, uint8: 1, bool: 1,
} as const;

function writeValue(
  view: DataView,
  type: ModelInferenceInputMapping["dataType"],
  index: number,
  value: number,
): void {
  const offset = index * bytesPerElement[type];
  switch (type) {
    case "float32": view.setFloat32(offset, value, true); return;
    case "float64": view.setFloat64(offset, value, true); return;
    case "int64": view.setBigInt64(offset, BigInt(Math.trunc(value)), true); return;
    case "int32": view.setInt32(offset, value, true); return;
    case "int16": view.setInt16(offset, value, true); return;
    case "int8": view.setInt8(offset, value); return;
    case "uint8": view.setUint8(offset, value); return;
    case "bool": view.setUint8(offset, value === 0 ? 0 : 1);
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
