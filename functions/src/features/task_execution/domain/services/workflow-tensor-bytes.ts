import {err, ok, type Result} from "neverthrow";
import {type NodeFailure} from "../entities/node-failure.js";
import {nodeFailures} from "../entities/node-failures.js";
import {type ModelInferenceInputMapping} from "../entities/task.js";

type NumericDataType = Exclude<ModelInferenceInputMapping["dataType"], "string">;

/** Kodiert Zahlen eines Workflow-Werts als Little-Endian-Bytes eines Modelltensors. */
export function bytesFor(
  dataType: NumericDataType,
  values: readonly number[],
): Result<Uint8Array, NodeFailure> {
  if (dataType === "float16" && !supportsFloat16()) return err(nodeFailures.capabilityUnavailable("float16Tensors"));
  const bytes = new Uint8Array(values.length * bytesPerElement[dataType]);
  const view = new DataView(bytes.buffer);
  values.forEach((value, index) => writeValue(view, dataType, index, value));
  return ok(bytes);
}

export const bytesPerElement = {
  float32: 4, float16: 2, float64: 8, int64: 8, int32: 4,
  int16: 2, int8: 1, uint8: 1, bool: 1,
} as const;

function writeValue(
  view: DataView,
  type: NumericDataType,
  index: number,
  value: number,
): void {
  const offset = index * bytesPerElement[type];
  switch (type) {
    case "float32": view.setFloat32(offset, value, true); return;
    case "float16": writeFloat16(view, offset, value); return;
    case "float64": view.setFloat64(offset, value, true); return;
    case "int64": view.setBigInt64(offset, BigInt(Math.trunc(value)), true); return;
    case "int32": view.setInt32(offset, value, true); return;
    case "int16": view.setInt16(offset, value, true); return;
    case "int8": view.setInt8(offset, value); return;
    case "uint8": view.setUint8(offset, value); return;
    case "bool": view.setUint8(offset, value === 0 ? 0 : 1);
  }
}

type Float16View = DataView & {setFloat16?: (offset: number, value: number, littleEndian: boolean) => void};

/** Node kennt `DataView.setFloat16` erst ab Version 24. */
function supportsFloat16(): boolean {
  return typeof (DataView.prototype as Float16View).setFloat16 === "function";
}

function writeFloat16(view: DataView, offset: number, value: number): void {
  (view as Float16View).setFloat16?.(offset, value, true);
}
