import {err, ok, Result} from "neverthrow";
import {
  type ModelInputValue,
} from "../../../machine_learning/domain/entities/model-input-source.js";
import {
  type ModelTensor,
} from "../../../machine_learning/domain/entities/model-tensor.js";
import {
  type TeamFileContentReader,
} from "../../../files/domain/repositories/team-file-content-reader.js";
import {type NodeFailure} from "../entities/node-failure.js";
import {nodeFailures, type ExpectedValue} from "../entities/node-failures.js";
import {
  type ModelInferenceInputMapping,
} from "../entities/task.js";
import {bytesFor, bytesPerElement} from "./workflow-tensor-bytes.js";

type InputOrFailure<T> = Result<T, NodeFailure>;

export async function modelInputFromWorkflowMapping(
  mapping: ModelInferenceInputMapping,
  value: unknown,
  teamId: string,
  fileContentReader: TeamFileContentReader,
): Promise<InputOrFailure<ModelInputValue>> {
  const mismatch = (expected: ExpectedValue) => nodeFailures.valueTypeMismatch("modelInput", expected, mapping.modelInputName);
  switch (mapping.sourceType) {
    case "image":
    case "audio":
    case "file":
      return fileInput(mapping.sourceType, value, teamId, fileContentReader, mismatch);
    case "text": return ok({type: "text", value: textValue(value)});
    case "datetime": return ok({type: "datetime", value: textValue(value)});
    case "number": return numberValue(value, mismatch).map((number) => ({type: "number", value: number}));
    case "boolean": return booleanValue(value, mismatch).map((boolean) => ({type: "boolean", value: boolean}));
    case "json": return jsonValue(value, mismatch).map((json) => ({type: "json", value: json}));
    case "tensor": return tensorFor(mapping, value, mismatch).map((tensor) => ({type: "tensor", tensor}));
  }
}

type Mismatch = (expected: ExpectedValue) => NodeFailure;

async function fileInput(
  type: "image" | "audio" | "file",
  value: unknown,
  teamId: string,
  reader: TeamFileContentReader,
  mismatch: Mismatch,
): Promise<InputOrFailure<ModelInputValue>> {
  if (!isRecord(value) || typeof value.fileId !== "string" || typeof value.versionId !== "string") {
    return err(mismatch("file"));
  }
  const content = await reader.readTeamFileContent(teamId, value.fileId, value.versionId);
  if (type === "image" && !content.contentType.startsWith("image/")) return err(mismatch("image"));
  if (type === "audio" && !content.contentType.startsWith("audio/")) return err(mismatch("audio"));
  return ok({type, contentType: content.contentType, bytes: content.content});
}

function textValue(value: unknown): string {
  if (typeof value === "string") return value;
  return JSON.stringify(value);
}

function numberValue(value: unknown, mismatch: Mismatch): InputOrFailure<number> {
  const number = typeof value === "number" ? value : Number(value);
  return Number.isFinite(number) ? ok(number) : err(mismatch("number"));
}

function booleanValue(value: unknown, mismatch: Mismatch): InputOrFailure<boolean> {
  if (typeof value === "boolean") return ok(value);
  if (value === "true") return ok(true);
  if (value === "false") return ok(false);
  return err(mismatch("boolean"));
}

function jsonValue(value: unknown, mismatch: Mismatch): InputOrFailure<unknown> {
  if (typeof value !== "string") return ok(value);
  try {
    return ok(JSON.parse(value) as unknown);
  } catch {
    return err(mismatch("json"));
  }
}

function tensorFor(mapping: ModelInferenceInputMapping, value: unknown, mismatch: Mismatch): InputOrFailure<ModelTensor> {
  if (isRecord(value) && typeof value.dataBase64 === "string") return serializedTensor(mapping.modelInputName, value, mismatch);
  return jsonValue(value, mismatch)
    .andThen((raw) => mapping.dataType === "string" ? textValues(raw, mismatch) : numericValues(raw, mismatch))
    .andThen((values) => shapeFor(mapping, values.length).andThen((shape) => {
      if (elementCount(shape) !== values.length) return err(nodeFailures.tensorShapeMismatch(mapping.modelInputName));
      return tensorBytes(mapping, values).map((bytes) => ({
        name: mapping.modelInputName, dataType: mapping.dataType, shape, bytes,
      }));
    }));
}

function tensorBytes(mapping: ModelInferenceInputMapping, values: unknown[]): InputOrFailure<Uint8Array> {
  if (mapping.dataType === "string") return ok(new TextEncoder().encode(JSON.stringify(values)));
  return bytesFor(mapping.dataType, values as number[]);
}

/** Ein Tensor-Ausgang eines vorherigen Modells (Base64, Datentyp, Form). */
function serializedTensor(name: string, value: Record<string, unknown>, mismatch: Mismatch): InputOrFailure<ModelTensor> {
  const dataType = value.dataType;
  const shape = value.shape;
  if (typeof dataType !== "string" || !(dataType in bytesPerElement || dataType === "string")) return err(mismatch("tensor"));
  if (!Array.isArray(shape) || !shape.every((dimension) => Number.isSafeInteger(dimension) && dimension > 0)) {
    return err(mismatch("tensor"));
  }
  return ok({
    name,
    dataType: dataType as ModelInferenceInputMapping["dataType"],
    shape: shape as number[],
    bytes: Uint8Array.from(Buffer.from(value.dataBase64 as string, "base64")),
  });
}

/** String-Tensoren tragen ihre Werte als UTF-8-JSON-Array in Zeilenfolge. */
function textValues(value: unknown, mismatch: Mismatch): InputOrFailure<string[]> {
  if (typeof value === "string") return ok([value]);
  if (!Array.isArray(value)) return err(mismatch("textList"));
  return Result.combine(value.map((item) => textValues(item, mismatch))).map((lists) => lists.flat());
}

function numericValues(value: unknown, mismatch: Mismatch): InputOrFailure<number[]> {
  if (typeof value === "number") return numberValue(value, mismatch).map((number) => [number]);
  if (!Array.isArray(value)) return err(mismatch("numberList"));
  return Result.combine(value.map((item) => numericValues(item, mismatch))).map((lists) => lists.flat());
}

function shapeFor(mapping: ModelInferenceInputMapping, length: number): InputOrFailure<number[]> {
  const dynamicCount = mapping.shape.filter((value) => value === "dynamic").length;
  const fixed = mapping.shape.filter((value): value is number => typeof value === "number");
  if (dynamicCount === 0) return ok(fixed);
  const fixedCount = elementCount(fixed);
  if (dynamicCount > 1 || length % fixedCount !== 0) return err(nodeFailures.tensorShapeMismatch(mapping.modelInputName));
  return ok(mapping.shape.map((value) => value === "dynamic" ? length / fixedCount : value));
}

function elementCount(shape: readonly number[]): number {
  return shape.reduce((count, dimension) => count * dimension, 1);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
